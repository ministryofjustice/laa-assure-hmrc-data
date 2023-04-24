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
end
