class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
 def azure_ad
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user&.persisted?
      sign_in_and_redirect @user, event: :authentication
    else
      flash[:alert] = @user.errors.full_messages.join("<br>")
      Rails.logger.error "Couldn't login user: #{@user.errors.inspect}"
      redirect_back(fallback_location: root_path, allow_other_host: false) # Don't redirect back to Microsoft
    end
  end

  def failure
    redirect_to unauthenticated_root_path
  end
end
