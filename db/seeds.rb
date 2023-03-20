# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#

attribute_sets = [
  { email: 'joel.sugarman@justice.gov.uk', first_name: 'Joel', last_name: 'Sugarman', provider: 'azure_ad' },
]

attribute_sets.each do |attributes|
  User.create_or_find_by!(attributes)
end
