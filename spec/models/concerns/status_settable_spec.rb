require "rails_helper"

RSpec.describe StatusSettable, type: :concern do
  let(:instance) { klass.new }

  let(:klass) do
    Class.new do
      include StatusSettable

      attr_accessor :status

      has_status :pending, :processing

      def update!(options)
        if options[:status].present?
          self.status = options[:status]
        end
      end
    end
  end

  describe "#pending!" do
    subject(:pending!) { instance.pending! }

    it "changes status to pending" do
      instance.status = "initial"

      expect { pending! }
        .to change(instance, :status)
          .from("initial")
          .to("pending")
    end
  end

  describe "#pending?" do
    subject(:pending?) { instance.pending? }

    it "returns true if status pending" do
      instance.update!(status: "pending")
      expect(pending?).to be true
    end

    it "returns false if status not pending" do
      instance.update!(status: "initial")
      expect(pending?).to be false
    end
  end

  describe "#processing!" do
    subject(:processing!) { instance.processing! }

    it "changes status to processing" do
      instance.status = "initial"

      expect { processing! }
        .to change(instance, :status)
          .from("initial")
          .to("processing")
    end
  end

  describe "#processing?" do
    subject(:processing?) { instance.processing? }

    it "returns true if status processing" do
      instance.update!(status: "processing")
      expect(processing?).to be true
    end

    it "returns false if status not processing" do
      instance.update!(status: "initial")
      expect(processing?).to be false
    end
  end
end
