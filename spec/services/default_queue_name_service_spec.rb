require "rails_helper"

RSpec.describe DefaultQueueNameService do
  describe ".call" do
    subject(:call) { described_class.call }

    context "when the service is called in UAT" do
      before do
        allow(Rails.configuration.x).to receive(:host_env).and_return("uat")
        allow(Rails.configuration.x.status).to receive(:app_branch).and_return(
          "this-is/a.test-branch"
        )
      end

      it "suffixes the submission queue name with the branch name" do
        expect(call).to eq "default-this-is-a-test-branch"
      end
    end

    context "when the service is called in UAT with special characters in branch name" do
      before do
        allow(Rails.configuration.x).to receive(:host_env).and_return("uat")
        allow(Rails.configuration.x.status).to receive(:app_branch).and_return(
          " this-is/a[test.branch](here)"
        )
      end

      it "suffixes the submission queue name with the branch name" do
        expect(call).to eq "default--this-is-a-test-branch--here-"
      end
    end

    context "when the service is called anywhere other than UAT" do
      before do
        allow(Rails.configuration.x).to receive(:host_env).and_return("foobar")
      end

      it "sets the submission queue name to /submissions/" do
        expect(call).to eq "default"
      end
    end
  end
end
