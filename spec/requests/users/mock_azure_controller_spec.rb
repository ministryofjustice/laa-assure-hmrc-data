require "system_helper"

RSpec.describe Users::MockAzureController, type: :request do
  describe "GET users/mock_azure" do
    before do
      allow(Rails.configuration.x).to receive(:mock_azure).and_return("true")
      allow(Rails.configuration.x).to receive(:mock_azure_password).and_return("mockazurepassword")
      Rails.application.reload_routes!
      get user_session_path
    end

    context "when mock_azure is true and user attempts to sign in" do
      it "displays log in page" do
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Log in")
      end
    end
  end

  describe "POST users/mock_azure#create" do
    before do
      user
      allow(Rails.configuration.x).to receive(:mock_azure).and_return("true")
      allow(Rails.configuration.x).to receive(:mock_azure_password).and_return("mockazurepassword")
      Rails.application.reload_routes!
      post user_session_path, params:
    end

    let(:user) do
      User.create!(email: "mock.azure@example.co.uk",
                   first_name: "Mock",
                   last_name: "Azure")
    end

    context "when username and password are correct" do
      let(:params) { { user: { email: 'mock.azure@example.co.uk', password: 'mockazurepassword' } } }

      it "redirects to authenticated users root path" do
        expect(flash[:notice]).to match(/Signed in successfully./)
        expect(response).to redirect_to(authenticated_root_path)
      end
    end

    context "when user doesn't exist" do
      let(:params) { { user: { email: 'no.user@example.co.uk', password: 'mockazurepassword' } } }

      it "redirects to fallback location and sets flash" do
        expect(flash[:notice]).to match(/User not found or authorised!/)
        expect(response).to redirect_to(unauthenticated_root_path)
      end
    end

    context "when password is incorrect" do
      let(:params) { { user: { email: 'mock.azure@example.co.uk', password: 'awrongpassword' } } }

      it "redirects to fallback location and sets flash" do
        expect(flash[:notice]).to match(/User not found or authorised!/)
        expect(response).to redirect_to(unauthenticated_root_path)
      end
    end
  end
end
