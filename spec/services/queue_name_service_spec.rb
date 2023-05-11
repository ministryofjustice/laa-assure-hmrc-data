require "rails_helper"

RSpec.describe QueueNameService do
  let(:use_case) { 'one' }

  describe ".call" do
    subject(:call) { described_class.call(use_case) }

    context "when the service is called in UAT for use case one" do
      before do
        allow(Rails.configuration.x).to receive(:host_env).and_return("uat")
        allow(Rails.configuration.x.status).to receive(:app_branch).and_return("this-is/a.test-branch")
      end

      it "prefixes the submission queue name with the branch name" do
        expect(call).to eq "uc-one-this-is-a-test-branch-submissions"
      end
    end

    context "when the service is called anywhere other than UAT for use case two" do
      let(:use_case) { 'two' }

      before do
        allow(Rails.configuration.x).to receive(:host_env).and_return("test")
      end

      it "sets the submission queue name to /submissions/" do
        expect(call).to eq "uc-two-submissions"
      end
    end
  end
end
