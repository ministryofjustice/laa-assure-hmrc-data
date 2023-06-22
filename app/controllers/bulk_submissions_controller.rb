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
      "Removed \"#{bulk_submission.original_file.filename}\""
    when "cancel"
      "Cancelled \"#{bulk_submission.original_file.filename}\""
    end

    redirect_to authenticated_root_path
  end

  # NOTE: route only available in test/development or uat
  def process_all
    BulkSubmissionsWorker.perform_async

    flash[:notice] = "processing all pending bulk submissions..."
    redirect_back(fallback_location: authenticated_root_path)
  end

  def bulk_submission_params
    params.permit(:id, :context)
  end
end
