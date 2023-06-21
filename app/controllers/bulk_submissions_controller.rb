class BulkSubmissionsController < ApplicationController
  def show
    @bulk_submission = BulkSubmission.find(params[:id])
    @context = params[:context]
  end

  def index
    @bulk_submissions = BulkSubmission.undiscarded.order(created_at: :desc)
  end

  def destroy
    bulk_submission = BulkSubmission.find(params[:id])
    bulk_submission.discard!

    flash[:notice] = "Deleted \"#{bulk_submission.original_file.filename}\""
    redirect_to authenticated_root_path
  end

  # NOTE: route only available in test/development or uat
  def process_all
    BulkSubmissionsWorker.perform_async

    flash[:notice] = "processing all pending bulk submissions..."
    redirect_back(fallback_location: authenticated_root_path)
  end
end
