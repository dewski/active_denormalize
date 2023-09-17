# frozen_string_literal: true

module ActiveDenormalize
  module Associations
    # ActiveDenormalize is a gem that allows you to denormalize data across your
    # ActiveRecord models. It currently supports `belongs_to` relationships.
    module Extension
      OPTIONS = [:denormalize].freeze

      def self.build(model, reflection)
        return unless reflection.options[:denormalize]

        define_accessors(model, reflection)
        add_after_commit_callback(model, reflection)
      end

      def self.valid_options
        OPTIONS
      end

      def self.define_accessors(model, reflection)
        denormalized_column_prefix = model.model_name.singular
        target_mixin = reflection.klass.generated_association_methods

        target_mixin.class_eval do
          define_method("clear_denormalized_#{denormalized_column_prefix}") do
            denormalized_columns = model.denormalized_column_mapping.keys & self.class.column_names
            cleared_denormalized_attributes = denormalized_columns.index_with { |_column| nil }
            update!(cleared_denormalized_attributes)
          end
        end

        model.class_eval do
          # Needed to lookup the next valid record to denormalize when destroying the latest record.
          scope :denormalize, -> {}

          def denormalize?
            true
          end

          def denormalize(target)
            denormalized_columns = self.class.denormalized_column_mapping.keys & target.class.column_names
            attributes = denormalized_columns.to_h do |denormalized_column|
              column = self.class.denormalized_column_mapping[denormalized_column]

              if column == "denormalized_at"
                [denormalized_column, Time.zone.now]
              else
                value = send(column)
                if (enum_mapping = defined_enums[column])
                  value = enum_mapping.fetch(value)
                end

                [denormalized_column, value]
              end
            end

            if attributes.empty?
              Rails.logger.debug { "No denormalized columns found for #{target.class}" }
            else
              Rails.logger.debug { "Denormalizing #{target.class} #{target.id} with #{attributes}" }
              target.update!(attributes)
            end
          end

          def self.denormalized_column_mapping
            @denormalized_column_mapping ||= begin
              prefix = model_name.singular

              mapping = column_names.index_by do |column_name|
                "#{prefix}_#{column_name}"
              end
              mapping["#{prefix}_denormalized_at"] = "denormalized_at"
              mapping
            end
          end
        end
      end

      def self.add_after_commit_callback(model, reflection)
        denormalized_column_prefix = model.model_name.singular
        denormalized_primary_key = "#{denormalized_column_prefix}_#{model.primary_key}"

        model.before_destroy do
          if (target = public_send(reflection.name))
            primary_key = public_send(self.class.primary_key)
            denormalized_primary_key_id = target.public_send(denormalized_primary_key)

            # The record being destroyed is currently denormalized on its association and needs to be replaced
            if denormalized_primary_key_id == primary_key
              replacement = target.association(model.model_name.collection).scope.denormalize.where.not(id: primary_key).order(created_at: :desc).first
              if replacement.present?
                replacement.denormalize(target)
              else
                target.public_send("clear_denormalized_#{denormalized_column_prefix}")
              end
            end
          end
        end

        model.after_create_commit do
          if denormalize? && (target = public_send(reflection.name))
            denormalize(target)
          end
        end

        model.after_update_commit do
          if (target = public_send(reflection.name))
            primary_key = public_send(self.class.primary_key)
            denormalized_primary_key_id = target.public_send(denormalized_primary_key)

            # After an update of a denormalized record, check the association to see if it is still the current denormalized record or if it has changed.
            denormalize(target) if denormalized_primary_key_id == primary_key
          end
        end
      end
    end
  end
end
