class BulkSubmissionFormsController < ApplicationController
  def new
    @form = BulkSubmissionForm.new
  end

  def create
    @form = BulkSubmissionForm.new(bulk_submission_form_params.merge(user_id: current_user.id, status: "pending"))

    respond_to do |format|
      format.html { respond_to_create_with_html }
      format.json { respond_to_create_with_json }
    end
  end

  def edit
    @form = BulkSubmissionForm.new(bulk_submission: bulk_submission_from_params)
  end

  def update
    @form = BulkSubmissionForm.new(bulk_submission_form_params
                                     .except(:id)
                                     .merge(bulk_submission: bulk_submission_from_params,
                                            user_id: current_user.id))

    respond_to do |format|
      format.html { respond_to_update_with_html }
      format.json { response_to_update_with_json }
    end
  end

  def destroy
    @bulk_submission = bulk_submission_from_params
    @bulk_submission.original_file.purge
    @bulk_submission.destroy!

    redirect_to new_bulk_submission_form_path
  end

private

  def bulk_submission_from_params
    BulkSubmission.find(bulk_submission_form_params[:id])
  end

  def bulk_submission_form_params
    params.permit(:id, :uploaded_file)
  end

  def upload_button_pressed?
    params[:commit] == "upload"
  end

  def continue_button_pressed?
    params[:commit] == "continue"
  end

  def respond_to_create_with_html
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

  def respond_to_create_with_json
    if @form.save
      head :created, location: edit_bulk_submission_form_url(@form.bulk_submission.id)
    else
      render json: { errors: @form.errors }, status: :unprocessable_entity
    end
  end

  def respond_to_update_with_html
    if params[:uploaded_file].nil? && continue_button_pressed?
      if @form.valid?
        redirect_to bulk_submissions_path
      else
        render :edit, id: bulk_submission_form_params[:id]
      end

    elsif params[:uploaded_file].nil? && upload_button_pressed?
      @form.errors.add(:uploaded_file, :blank)
      render :edit, id: bulk_submission_form_params[:id]

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

  def response_to_update_with_json
    if @form.update
      head :accepted, location: edit_bulk_submission_form_url(@form.bulk_submission.id)
    else
      render json: { errors: @form.errors }, status: :unprocessable_entity
    end
  end
end
