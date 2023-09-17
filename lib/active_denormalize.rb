# frozen_string_literal: true

require "active_denormalize/version"
require "active_denormalize/associations/extension"

ActiveRecord::Associations::Builder::Association.extensions << ActiveDenormalize::Associations::Extension
