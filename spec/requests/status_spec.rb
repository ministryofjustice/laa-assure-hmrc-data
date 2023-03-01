require "rails_helper"

RSpec.describe StatusController do
  describe "#healthcheck" do
    context "when there is a problem with the database" do
      before do
        allow(ActiveRecord::Base.connection).to receive(:active?).and_raise(PG::ConnectionBad, "error")
        get "/healthcheck"
      end

      let(:failed_healthcheck) do
        {
          checks: {
            database: false,
          }
        }.to_json
      end

      it "returns status bad gateway" do
        expect(response).to have_http_status :bad_gateway
      end

      it "returns the expected response report" do
        expect(response.body).to eq(failed_healthcheck)
      end
    end

    context "when everything is ok" do
      before do
        allow(ActiveRecord::Base.connection).to receive(:active?).and_return(true)
        get "/healthcheck"
      end

      let(:expected_response) do
        {
          checks: {
            database: true,
          },
        }.to_json
      end

      it "returns HTTP success" do
        get "/healthcheck"
        expect(response).to have_http_status(:ok)
      end

      it "returns the expected response report" do
        get "/healthcheck"
        expect(response.body).to eq(expected_response)
      end
    end
  end

  describe "#ping" do
    context "when environment variables set" do
      let(:expected_json) do
        {
          "build_date" => "20220301",
          "build_tag" => "test",
          "git_commit" => "ab12345",
        }
      end

      before do
        allow(Rails.configuration.x.status).to receive_messages(build_date: "20220301",
                                                                build_tag: "test",
                                                                git_commit: "ab12345")
        get("/ping")
      end

      it "returns JSON with app information" do
        expect(JSON.parse(response.body)).to eq(expected_json)
      end
    end

    context "when environment variables not set" do
      before do
        allow(Rails.configuration.x.status).to receive_messages(build_date: "Not Available",
                                                                build_tag: "Not Available",
                                                                git_commit: "Not Available")
        get "/ping"
      end

      it 'returns "Not Available"' do
        expect(JSON.parse(response.body).values).to be_all("Not Available")
      end
    end
  end
end
