require "system_helper"

RSpec.describe "sign in", type: :system do
  it "has a Start now button" do
    visit "/"
    expect(page).to have_button('Start now')
  end
end
