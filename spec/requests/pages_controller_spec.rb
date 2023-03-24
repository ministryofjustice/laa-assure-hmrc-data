require "system_helper"

RSpec.describe PagesController, type: :request do
  describe "#landing" do
    it "returns http success" do
      get "/"
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Start now")
    end
  end

  describe "#home" do
    before { sign_in user }

    let(:user) do
      User.create!(email: "Jim.Bob@example.co.uk",
                   first_name: "Jim",
                   last_name: "Bob",
                   auth_provider: "azure_ad")
    end

    it "returns http success" do
      get "/"
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Sign out")
    end
  end
end
