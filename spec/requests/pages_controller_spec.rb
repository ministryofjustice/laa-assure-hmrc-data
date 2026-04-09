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
      allow(Rails.configuration.x.business_hours).to receive_messages(start: "7:00", end: "22:00")
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
        expect(response.body).to include("This service is available daily from 7am to 10pm.")
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
        let(:new_time) { Time.find_zone('London').parse('2025-09-08 06:59') }

        it_behaves_like "out of hours access"
      end

      context "when it's 0700 on a Monday" do
        let(:new_time) { Time.find_zone('London').parse('2025-09-08 07:00') }

        it_behaves_like "in hours access"
      end

      context "when it's 0900 on a Monday" do
        let(:new_time) { Time.find_zone('London').parse('2025-09-08 09:00') }

        it_behaves_like "in hours access"
      end

      context "when it's 2159 on a Monday" do
        let(:new_time) { Time.find_zone('London').parse('2025-09-08 21:59') }

        it_behaves_like "in hours access"
      end

      context "when it's 2200 on a Monday" do
        let(:new_time) { Time.find_zone('London').parse('2025-09-08 22:00') }

        it_behaves_like "out of hours access"
      end

      context "when it's 1300 on a Sunday" do
        let(:new_time) { Time.find_zone('London').parse('2025-09-07 13:00') }

        it_behaves_like "in hours access"
      end
    end

    context "when it's GMT" do
      context "when it's 0630 on a Monday" do
        let(:new_time) { Time.find_zone('London').parse('2025-11-03 06:30') }

        it_behaves_like "out of hours access"
      end

      context "when it's 0730 on a Monday" do
        let(:new_time) { Time.find_zone('London').parse('2025-11-03 07:30') }

        it_behaves_like "in hours access"
      end

      context "when it's 1830 on a Monday" do
        let(:new_time) { Time.find_zone('London').parse('2025-11-03 18:30') }

        it_behaves_like "in hours access"
      end

      context "when it's 2200 on a Monday" do
        let(:new_time) { Time.find_zone('London').parse('2025-11-03 22:00') }

        it_behaves_like "out of hours access"
      end
    end
  end
end
