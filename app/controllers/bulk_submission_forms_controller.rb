class BulkSubmissionFormsController < ApplicationController

  def new
    @form = BulkSubmissionForm.new
  end

  def create
    @form = BulkSubmissionForm.new(bulk_submission_form_params.merge(user_id: current_user.id, status: "pending"))

    if @form.save
      if upload_button_pressed?
        redirect_to edit_bulk_submission_form_path(@form.bulk_submission.id)
      else
        redirect_to bulk_submissions_path
      end
    else
      render :new
    end
  end

  def edit
    bulk_submission = BulkSubmission.find(params[:id])
    @form = BulkSubmissionForm.new(bulk_submission:)
  end

  def update
    @form = BulkSubmissionForm.new(bulk_submission_form_params.merge(bulk_submission: BulkSubmission.find(params[:id])))

    if params[:uploaded_file].nil? && continue_button_pressed?
      if @form.valid?
        redirect_to bulk_submissions_path
      else
        render :edit, id: params[:id]
      end

    elsif params[:uploaded_file].nil? && upload_button_pressed?
      @form.errors.add(:uploaded_file, :blank)
      render :edit, id: params[:id]

    elsif @form.update
      if upload_button_pressed?
        redirect_to edit_bulk_submission_form_path(@form.bulk_submission.id)
      else
        redirect_to bulk_submissions_path
      end
    else
      render :edit
    end
  end

  def destroy
    @bulk_submission = BulkSubmission.find(params[:id])
    @bulk_submission.original_file.purge
    @bulk_submission.destroy!

    redirect_to new_bulk_submission_form_path
  end

  private

  def bulk_submission_form_params
    params.permit(:uploaded_file)
  end

  def upload_button_pressed?
    params[:commit] == "upload"
  end

  def continue_button_pressed?
    params[:commit] == "continue"
  end
end
