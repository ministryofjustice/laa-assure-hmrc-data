require "system_helper"

RSpec.describe Users::OmniauthCallbacksController, type: :request do
  describe "POST users/auth/azure_ad/callback" do
    before do
      user
      allow(Rails.logger).to receive(:error).and_call_original
      post user_azure_ad_omniauth_callback_path
    end

    context "when applicable user exists" do
      let(:user) do
        User.create!(
          email: "Jim.Bob@example.co.uk",
          first_name: "Jim",
          last_name: "Bob",
          auth_provider: "azure_ad"
        )
      end

      it "redirects to authenticated users root path" do
        expect(flash[:notice]).to match(/Signed in successfully./)
        expect(response).to redirect_to(authenticated_root_path)
      end
    end

    context "when no applicable user exists" do
      let(:user) { nil }

      it "redirects to fallback location, logs and sets flash" do
        expect(flash[:notice]).to match(/User not found or authorised!/)
        expect(Rails.logger).to have_received(:error).with(
          "Couldn't login user"
        )
        expect(response).to redirect_to(unauthenticated_root_path)
      end
    end

    context "when omniauth fails", omniauth_failure: true do
      let(:user) { nil }

      it "redirects to unauthenticated root" do
        expect(flash[:alert]).to match(
          /There has been a problem authenticating you!/
        )
        expect(Rails.logger).to have_received(:error).with(
          "omniauth error authenticating a user!"
        )
        expect(response).to redirect_to(unauthenticated_root_path)
      end
    end
  end
end
