class Users::MockAzureController < Devise::SessionsController
  def create
    user = User.find_by(email: mock_azure_params[:email])

    if user &&
        mock_azure_params[:email] == Rails.configuration.x.mock_azure_username &&
        mock_azure_params[:password] == Rails.configuration.x.mock_azure_password
      flash[:notice] = I18n.t "devise.sessions.signed_in"
      sign_in_and_redirect user, event: :authentication
    else
      flash[:notice] = I18n.t "devise.omniauth_callbacks.unauthorised"
      redirect_back(fallback_location: unauthenticated_root_path)
    end
  end

  private

  def mock_azure_params
    params.require(:user).permit(:email, :password)
  end
end
