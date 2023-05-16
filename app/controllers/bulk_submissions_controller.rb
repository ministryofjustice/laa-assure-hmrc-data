class BulkSubmissionsController < ApplicationController
  def index
    @bulk_submissions = BulkSubmission.all
  end

  def destroy
    bulk_submission = BulkSubmission.find(params[:id])
    bulk_submission.original_file.purge
    bulk_submission.destroy!
    redirect_back(fallback_location: authenticated_root_path)
  end

  # route only available in development/uat, for testing
  def process_all
    BulkSubmissionsWorker.perform_async

    flash[:notice] = "processing all pending bulk submissions..."
    redirect_back(fallback_location: authenticated_root_path)
  end
end
