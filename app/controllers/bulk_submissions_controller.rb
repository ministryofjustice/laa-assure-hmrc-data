class BulkSubmissionsController < ApplicationController
  def show
    @bulk_submission = BulkSubmission.find(bulk_submission_params[:id])
    @context = bulk_submission_params[:context]
  end

  def index
    @bulk_submissions = BulkSubmission.undiscarded.order(created_at: :desc)
  end

  def destroy
    bulk_submission = BulkSubmission.find(bulk_submission_params[:id])
    bulk_submission.discard!

    flash[:notice] = case bulk_submission_params[:context]
    when "remove"
      I18n.t(
        "bulk_submissions.flash.removed",
        filename: bulk_submission.original_file.filename
      )
    when "cancel"
      I18n.t(
        "bulk_submissions.flash.cancelled",
        filename: bulk_submission.original_file.filename
      )
    end

    redirect_to authenticated_root_path
  end

  def download
    bulk_submission = BulkSubmission.find(params[:id])
    Rails.logger.info "User #{current_user.id} downloaded results file for bulk submission #{bulk_submission.id}"
    attachment = bulk_submission.result_file.attachment
    send_data attachment.blob.download,
              filename: attachment.filename.to_s,
              content_type: "text/csv"
  end

  # NOTE: route only available in test/development or uat
  def process_all
    BulkSubmissionsWorker.perform_async

    flash[:notice] = I18n.t("bulk_submissions.flash.process_all")
    redirect_back(fallback_location: authenticated_root_path)
  end

  def bulk_submission_params
    params.permit(:id, :context)
  end
end
