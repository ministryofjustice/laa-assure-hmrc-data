class BulkSubmissionsController < ApplicationController
  def index
    @bulk_submissions = BulkSubmission.undiscarded.order(created_at: :desc)
  end

  def destroy
    bulk_submission = BulkSubmission.find(params[:id])
    bulk_submission.discard!
    redirect_back(fallback_location: authenticated_root_path)
  end

  # NOTE: route only available in test/development or uat
  def process_all
    BulkSubmissionsWorker.perform_async

    flash[:notice] = "processing all pending bulk submissions..."
    redirect_back(fallback_location: authenticated_root_path)
  end
end
