require "rails_helper"

RSpec.describe BulkSubmissionResultWriterService do
  subject(:instance) { described_class.new(bulk_submission.id) }

  let(:bulk_submission) do
    create(:bulk_submission,
           :with_original_file,
           status: "completed").tap do |bs|
      bs.submissions.destroy_all
      bs.submissions << create(:submission, :for_john_doe,
                               use_case: :one, status: "completed",
                               hmrc_interface_result: { data: [{ use_case: "use_case_one" }] }.as_json)
      bs.submissions << create(:submission, :for_john_doe,
                               use_case: :two, status: "completed",
                               hmrc_interface_result: { data: [{ use_case: "use_case_two" }] }.as_json)
    end
  end

  describe "#bulk_submission" do
   it "returns the bulk_submission instance set at instatiation" do
    expect(instance.bulk_submission).to eql(bulk_submission)
   end
  end

  describe "#call" do
    subject(:call) { instance.call }

    it "updates status to \"writing\" as initial step" do
      allow(instance).to receive(:attach_result).and_raise ZeroDivisionError, "oops, something went wrong"
      call
    rescue ZeroDivisionError
      expect(bulk_submission.reload.status).to eq("writing")
    end

    it "updates status to \"ready\" when complete" do
      expect { call }
        .to change { bulk_submission.reload.status }
          .from("completed")
          .to("ready")
    end

    it "names the attachment after the original_file" do
      call
      expect(bulk_submission.result_file.filename.to_s)
        .to eql("#{bulk_submission.original_file.filename.base}-result.csv")
    end

    context "with results populated" do
      it "attaches a result_file with expected uc one only data, with csv headers and rows with forced quotes" do
        expect { call }
          .to change { bulk_submission.reload.result_file.attached? }
            .from(false)
            .to(true)

        expected_content = <<~CSV
          "period_start_date","period_end_date","first_name","last_name","date_of_birth","nino","status","comment","tax_credit_annual_award_amount","clients_income_from_employment","clients_ni_contributions_from_employment","start_and_end_dates_for_employments","most_recent_payment_from_employment","clients_income_from_self_employment","clients_income_from_other_sources","most_recent_payment_from_other_sources","uc_one_data","uc_two_data"
          "2020-10-01","2020-12-31","John","Doe","2001-07-21","JA123456D","completed","","","0","0","","","","0","","[\n  {\n    "\"use_case\"": "\"use_case_one"\"\n  }\n]","[\n  {\n    "\"use_case\"": "\"use_case_two"\"\n  }\n]"
        CSV

        expect(bulk_submission.result_file.download).to eql(expected_content)
      end
    end
  end

  describe ".call" do
    subject(:call) { described_class.call(bulk_submission.id) }

    let(:instance) { instance_double(described_class) }

    before do
      allow(described_class).to receive(:new).and_return(instance)
      allow(instance).to receive(:call)
    end

    it "sends call method to instance" do
      call
      expect(described_class).to have_received(:new).with(bulk_submission.id)
      expect(instance).to have_received(:call)
    end
  end
end
