RSpec.shared_examples "applcation worker logger" do
  let(:log_regex) do
    %r{\[\d{4}-\d{2}-\d{2}\s*\d{2}:\d{2}:\d{2}.*\] running #{described_class} with args: \[.*\]}
  end

  it "logs timestamp, class and args of run" do
    allow(Rails.logger).to receive(:info)
    perform
    expect(Rails.logger).to have_received(:info).with(log_regex)
  end
end
