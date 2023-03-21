class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
 def azure_ad
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user && @user&.persisted?
      sign_in_and_redirect @user, event: :authentication
    else
      flash[:alert] = "User not found or authorised!"
      Rails.logger.error "Couldn't login user"
      redirect_back(fallback_location: unauthenticated_root_path, allow_other_host: false)
    end
  end

  def failure
    redirect_to unauthenticated_root_path
  end
end
