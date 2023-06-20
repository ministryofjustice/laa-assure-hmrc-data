class BulkSubmissionsController < ApplicationController
  def index
    @bulk_submissions = BulkSubmission.all.undiscarded
  end

  def destroy
    bulk_submission = BulkSubmission.find(params[:id])
    bulk_submission.original_file.purge
    bulk_submission.destroy!
    redirect_back(fallback_location: authenticated_root_path)
  end

  def cancel
    bulk_submission = BulkSubmission.find(params[:id])
    bulk_submission.original_file.purge
    bulk_submission.destroy!
    redirect_back(fallback_location: authenticated_root_path)
  end

  def discard
    bulk_submission = BulkSubmission.find(params[:id])
    bulk_submission.discard
    redirect_back(fallback_location: authenticated_root_path)
  end

  # NOTE: route only available in test/development or uat
  def process_all
    BulkSubmissionsWorker.perform_async

    flash[:notice] = "processing all pending bulk submissions..."
    redirect_back(fallback_location: authenticated_root_path)
  end
end
