# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#

# DO NOT SEED OUR ACTUAL USERS THIS WAY
# as they are not public domain
test_users = [
  { email: 'joel.sugarman@justice.gov.uk', provider: 'azure_ad' },
]

test_users.each do |attributes|
  User.create_or_find_by!(attributes)
end
