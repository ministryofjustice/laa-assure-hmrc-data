require "system_helper"

RSpec.describe PagesController do
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

  describe "#service_out_of_hours" do
    before do
      allow(Rails.configuration.x.business_hours).to receive_messages(start: "7:00", end: "21:30")
    end

    around do |example|
      travel_to(new_time) { example.run }
    end

    after do
      allow(Rails.configuration.x.business_hours).to receive(:start).and_call_original
      allow(Rails.configuration.x.business_hours).to receive(:end).and_call_original
    end

    shared_examples "out of hours access" do
      it "blocks traffic" do
        get "/"
        expect(response).to render_template("pages/service_out_of_hours")
        expect(response.body).not_to include("Start now")
      end

      it "displays expected content" do
        get "/"
        expect(response.body).to include("This service is available daily from 7am to 9:30pm.")
      end
    end

    shared_examples "in hours access" do
      it "allows traffic" do
        get "/"
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Start now")
      end
    end

    context "when it's British Summer Time" do
      context "when it's 0659 on a Monday" do
        let(:new_time) { Time.zone.local(2025, 9, 8, 6, 59, 0) }

        it_behaves_like "out of hours access"
      end

      context "when it's 0700 on a Monday" do
        let(:new_time) { Time.zone.local(2025, 9, 8, 7, 0, 0) }

        it_behaves_like "in hours access"
      end

      context "when it's 0900 on a Monday" do
        let(:new_time) { Time.zone.local(2025, 9, 8, 9, 0, 0) }

        it_behaves_like "in hours access"
      end

      context "when it's 2129 on a Monday" do
        let(:new_time) { Time.zone.local(2025, 9, 8, 21, 29, 0) }

        it_behaves_like "in hours access"
      end

      context "when it's 2130 on a Monday" do
        let(:new_time) { Time.zone.local(2025, 9, 8, 21, 30, 0) }

        it_behaves_like "out of hours access"
      end

      context "when it's 1300 on a Sunday" do
        let(:new_time) { Time.zone.local(2025, 9, 7, 13, 0, 0) }

        it_behaves_like "in hours access"
      end
    end

    context "when it's GMT" do
      context "when it's 0630 on a Monday" do
        let(:new_time) { Time.zone.local(2025, 11, 3, 6, 30, 0) }

        it_behaves_like "out of hours access"
      end

      context "when it's 0730 on a Monday" do
        let(:new_time) { Time.zone.local(2025, 11, 3, 7, 30, 0) }

        it_behaves_like "in hours access"
      end

      context "when it's 1830 on a Monday" do
        let(:new_time) { Time.zone.local(2025, 11, 3, 18, 30, 0) }

        it_behaves_like "in hours access"
      end

      context "when it's 2200 on a Monday" do
        let(:new_time) { Time.zone.local(2025, 11, 3, 22, 0, 0) }

        it_behaves_like "out of hours access"
      end
    end
  end
end
