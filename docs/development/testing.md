# Testing

We use rspec for unit and system testing.

```shell
rspec -fd
```

# System testing

System tests are configured to run using `:rack_test` driver by default. For javascript dependant system tests you can use `js: true` metadata to switch to a custom registered `:headless_chrome` driver.

```ruby
# test using :rack_test driver
it "does something", type: :system do
  visit "/"
  expect(page).to have...
end

# test using :headless_chrome driver
it "does something depending on javascript", type: :system, js: true do
  visit "/"
  expect(page).to have...
end

```

To test with non-headless custom registered `:chrome` driver you can use
```sh
# test using :chrome driver
BROWSER=true bundle exec rspec
```

see `spec/system/support/*_helper.rb` for more details

# Omniauth stubbing

System tests use Omniauth config to stub a single user auth hash. As long as tests create a user that matches the `auth_subject_id` or `email` address and `auth_provider` for that user then you can sign in.

```ruby
before { User.create!(email: "Jim.Bob@example.co.uk", auth_provider: "azure_ad") }

it "signs in" do
  visit "/"
  click_button "Start now"
end
```

see `spec/system/support/omniauth_helper.rb` for more details
