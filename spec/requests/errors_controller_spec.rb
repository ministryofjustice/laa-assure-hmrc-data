# frozen_string_literal: true

require "rails_helper"

RSpec.describe ErrorsController do
  describe "#not_found" do
    before { get "/404" }

    it "returns status 404 and page not found content", :aggregate_failures do
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Page not found")
      expect(response.body).to include("If you entered a web address, check it is correct.")
      expect(response.body)
        .to match(%r{contact the "Check client&#39;s details using HMRC data" team})
        .and match(%r{.*apply-for-civil-legal-aid@digital.justice.gov.uk})
    end
  end

  describe "#unprocessable_content" do
    before { get "/422" }

    it "returns status 422 and unprocessable entity content", :aggregate_failures do
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Sorry, there’s a problem with the service")
      expect(response.body).to include("Try again later.")
      expect(response.body)
        .to match(%r{contact the "Check client&#39;s details using HMRC data"})
        .and match(%r{.*apply-for-civil-legal-aid@digital.justice.gov.uk})
    end
  end

  describe "#too_many_requests" do
    before { get "/429" }

    it "returns status 429 and too many request content", :aggregate_failures do
      expect(response).to have_http_status(:too_many_requests)
      expect(response.body).to include("Sorry, there’s a problem with the service")
      expect(response.body).to include("Try again later.")
      expect(response.body)
        .to match(%r{contact the "Check client&#39;s details using HMRC data"})
        .and match(%r{.*apply-for-civil-legal-aid@digital.justice.gov.uk})
    end
  end

  describe "#internal_server_error" do
    before { get "/500" }

    it "returns status 500 and internal server error content", :aggregate_failures do
      expect(response).to have_http_status(:internal_server_error)
      expect(response.body).to include("Sorry, there’s a problem with the service")
      expect(response.body).to include("Try again later.")
      expect(response.body).to include("You’ll need to enter it again when the service is available")
      expect(response.body).to match(
        %r{If you have any questions, please email us at.*apply-for-civil-legal-aid@digital.justice.gov.uk}
      )
    end
  end

  describe "#out_of_hours" do
    before { get "/out-of-hours" }

    # NOTE: using 500 as a 503 will trigger Cloud platform's fallback "Service unavailable" page
    it "returns status 500 and out of hours error content", :aggregate_failures do
      expect(response).to have_http_status(500)
      expect(response.body)
        .to include("System not available")
        .and include("Note that working hours are between 7am and 10pm on weekdays.")
        .and include("This service will not be available outside those times.")
        .and include("If this is unexpected and within working hours then please contact our technical support team:")

      expect(response.body).to match(
        %r{email.*apply-for-civil-legal-aid@digital.justice.gov.uk}
      )
    end
  end
end
