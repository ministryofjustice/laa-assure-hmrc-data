require "rails_helper"

RSpec.describe StatusController do
  describe "#healthcheck" do
    before do
      allow(ActiveRecord::Base.connection).to receive(:active?).and_return(true)
      allow(Sidekiq::ProcessSet).to receive(:new).and_return(instance_double(Sidekiq::ProcessSet, size: 1))
      allow(Sidekiq::RetrySet).to receive(:new).and_return(instance_double(Sidekiq::RetrySet, size: 0))
      allow(Sidekiq::DeadSet).to receive(:new).and_return(instance_double(Sidekiq::DeadSet, size: 0))
      connection = instance_double("connection", info: {})
      allow(Sidekiq).to receive(:redis).and_yield(connection)
    end

    context "when there is a problem with the database" do
      before do
        allow(ActiveRecord::Base.connection).to receive(:active?).and_raise(PG::ConnectionBad, "error")
        get "/healthcheck"
      end

      let(:failed_healthcheck) do
        {
          checks: {
            database: false,
            redis: true,
            sidekiq: true,
            sidekiq_queue: true,
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

    context "when there is a problem with redis" do
      before do
        allow(Sidekiq).to receive(:redis).and_yield(StandardError)
      end

      it "response is bad_gateway and body contains redis: false" do
        get "/healthcheck"
        expect(response).to have_http_status :bad_gateway
        expect(response.body).to include("\"redis\":false")
      end
    end

    context "when there is a problem with sidekiq" do
      before do
        allow(Sidekiq::ProcessSet).to receive(:new).and_raise(StandardError)
      end

      it "response is bad_gateway and body contains sidekiq: false" do
        get "/healthcheck"
        expect(response).to have_http_status :bad_gateway
        expect(response.body).to include("\"sidekiq\":false")
      end
    end

    context "when failed Sidekiq jobs exist" do
      before do
        allow(Sidekiq::RetrySet).to receive(:new).and_return(instance_double(Sidekiq::ProcessSet, size: 1))
        get "/healthcheck"
      end

      context "when dead set exists" do
        before do
          allow(Sidekiq::DeadSet).to receive(:new).and_return(instance_double(Sidekiq::DeadSet, size: 1))
          allow(Sidekiq::RetrySet).to receive(:new).and_return(instance_double(Sidekiq::RetrySet, size: 0))
          get "/healthcheck"
        end

        it "response is ok but body contains sidekiq_queue: false" do
          expect(response).to have_http_status :ok
          expect(response.body).to include("\"sidekiq_queue\":false")
        end
      end

      context "when retry set exists" do
        before do
          allow(Sidekiq::DeadSet).to receive(:new).and_return(instance_double(Sidekiq::DeadSet, size: 0))
          allow(Sidekiq::RetrySet).to receive(:new).and_return(instance_double(Sidekiq::RetrySet, size: 1))
          get "/healthcheck"
        end

        it "response is ok but body contains sidekiq_queue: false" do
          expect(response).to have_http_status :ok
          expect(response.body).to include("\"sidekiq_queue\":false")
        end
      end

      context "when retry or deadset queues raise StandardError" do
        before do
          allow(Sidekiq::DeadSet).to receive(:new).and_raise(StandardError)
          get "/healthcheck"
        end

        it "response is ok but body contains sidekiq_queue: false" do
          expect(response).to have_http_status :ok
          expect(response.body).to include("\"sidekiq_queue\":false")
        end
      end
    end

    context "when everything is ok" do
      before do
        get "/healthcheck"
      end

      let(:expected_response) do
        {
          checks: {
            database: true,
            redis: true,
            sidekiq: true,
            sidekiq_queue: true,
          },
        }.to_json
      end

      it "returns HTTP success and expected body" do
        get "/healthcheck"
        expect(response).to have_http_status(:ok)
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
