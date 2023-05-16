class BulkSubmissionMonitoringWorker < ApplicationWorker
  def perform(bulk_submission_id)
    bulk_submission = BulkSubmission.find(bulk_submission_id)

    # TODO: we could generate "result_file" CSV for bulk submission and attach to it here??!
    # but are the sub workers complete here??
    #
    # Ideas
    # 1. just use time
    #  FileGeneratorWorker.perform_in(10.minutes, bulk_submission_id)
    # 2. perform check in the sevice for all submissions being complete and run straight away
    #  FileGeneratorWorker.perform_async(bulk_submission_id)
    # as below

    # TESTING only
    1.upto(60) do |_n|
      submission_statuses = bulk_submission.submissions.reload.map(&:status)
      all_finished = submission_statuses.all? { |status| %w[failed completed].include?(status) }
      Rails.logger.debug "ALL STATUSES: #{submission_statuses}"

      if all_finished
        bulk_submission.update!(status: "completed")
        break
      end
      sleep 2
    end

    super
  end
end
