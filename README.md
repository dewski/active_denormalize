# ActiveDenormalize

ActiveDenormalize is a gem that allows you to denormalize data across your ActiveRecord models. It currently supports `belongs_to` relationships.

Below is a simple example which you can use to get started (and mostly until further documentation is added in this README).

```ruby
class Product < ApplicationRecord
  has_many :inventory_checks
end

class InventoryCheck < ApplicationRecord
  belongs_to :product, denormalize: true
end
```

ActiveDenormalize works by adding create, update, and destroy `after_*_commit` callbacks to the host model, in this case InventoryCheck, which will update the denormalized attributes on the Product model.

To know which attributes to denormalize on to the Product model, ActiveDenormalize will look for `inventory_check` prefixed columns on the Product model. For example, if you have a `inventory_check_id` column on the Product model, ActiveDenormalize will update that column with the ID of most recent InventoryCheck record that belong to the Product.

```ruby
# No InventoryCheck has been created yet
> product = Product.create(name: "Product 1")
> product.inventory_check_id
=> nil
> product.inventory_check_created_at
=> nil
> product.inventory_check_status
=> nil
> product.inventory_check_denormalized_at
=> nil

# Updates the Product record to know about the newest InventoryCheck
> first_inventory_check = InventoryCheck.create(product: product, status: "backordered")
> first_inventory_check.id
=> 1
> product.reload.inventory_check_id
=> 1
> product.inventory_check_created_at
=> Sun, 17 Sep 2023 17:28:13.674818427 UTC +00:00
> product.inventory_check_status
=> "backordered"
> product.inventory_check_denormalized_at
=> Sun, 17 Sep 2023 17:28:13.674818427 UTC +00:00

# Updates the Product record to know about the newest InventoryCheck
> second_inventory_check = InventoryCheck.create(product: product, status: "available")
> second_inventory_check.id
=> 2
> product.reload.inventory_check_id
=> 2
> product.inventory_check_created_at
=> Sun, 17 Sep 2023 17:28:53.903842001 UTC +00:00
> product.inventory_check_status
=> "available"
> product.inventory_check_denormalized_at
=> Sun, 17 Sep 2023 17:28:53.903842001 UTC +00:00
> second_inventory_check.destroy

# Reverts to the previous InventoryCheck record
> product.reload.inventory_check_id
=> 1
> product.inventory_check_created_at
=> Sun, 17 Sep 2023 17:28:13.674818427 UTC +00:00
> product.inventory_check_status
=> "backordered"
> product.inventory_check_denormalized_at
=> Sun, 17 Sep 2023 17:28:13.674818427 UTC +00:00

# Updates the denormalized representation of the InventoryCheck on Product
> first_inventory_check.update!(status: "available")
> product.reload.inventory_check_id
=> 1
> product.inventory_check_created_at
=> Sun, 17 Sep 2023 17:28:13.674818427 UTC +00:00
> product.inventory_check_status
=> "available"
> product.inventory_check_denormalized_at # This timestamp will be updated
=> Sun, 17 Sep 2023 17:31:16.388224345 UTC +00:00
```


## Installation

Add this line to your application's Gemfile:

```ruby
gem "active_denormalize"
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install active_denormalize
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/active_denormalize. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/active_denormalize/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
