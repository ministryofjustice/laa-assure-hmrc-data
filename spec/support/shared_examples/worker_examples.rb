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

RSpec.shared_examples "hmrc interface worker" do
  describe '.retry' do
    subject(:retry) { described_class.get_sidekiq_options['retry'] }

    it { is_expected.to be 5 }
  end

  describe '.sidekiq_retry_in' do
    subject(:config) { described_class }

    context "when try again error raised" do
      let(:exc) { HmrcInterface::TryAgain.new('only me') }

      it 'uses the default retry fallback interval' do
        expect(config.sidekiq_retry_in_block.call(1, exc)).to be_nil
        expect(config.sidekiq_retry_in_block.call(5, exc)).to be_nil
      end
    end

    context "when incomplete result error raised" do
      let(:exc) { HmrcInterface::IncompleteResult.new('only me') }

      before do
        allow(Rails.logger).to receive(:error)
      end

      it 'logs error message and sends :kill to move job to deadset' do
        expect(config.sidekiq_retry_in_block.call(1, exc)).to eq :kill
        expect(Rails.logger).to have_received(:error).with("only me")
      end
    end

    context "when request unacceptable result error raised" do
      let(:exc) { HmrcInterface::RequestUnacceptable.new('only me') }

      before do
        allow(Rails.logger).to receive(:error)
      end

      it 'logs error message and sends :kill to move job to deadset' do
        expect(config.sidekiq_retry_in_block.call(1, exc)).to eq :kill
        expect(Rails.logger).to have_received(:error).with("only me")
      end
    end

    context "when other error raised" do
      let(:exc) { StandardError.new('oops') }

      before do
        allow(Rails.logger).to receive(:error)
      end

      it 'sends nil to pickup sidekiq default interval alorithm' do
        expect(config.sidekiq_retry_in_block.call(1, exc)).to be_nil
      end
    end
  end
end
