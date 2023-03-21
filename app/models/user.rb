class User < ApplicationRecord
  # Include default devise modules.
  # Common modules are:
  # :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable
  # Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable

  devise :omniauthable , omniauth_providers: [:azure_ad]

  def self.from_omniauth(auth)
    user = find_by(auth_subject_id: auth.uid)

    if user
      user.update!(auth_last_sign_in_at: Time.current)
    else
      user = find_by(email: auth.info.email, provider: auth.provider, auth_subject_id: nil)

      if user
        user.update!(
          first_name: auth.info.first_name,
          last_name: auth.info.last_name,
          auth_subject_id: auth.uid,
          auth_last_sign_in_at: Time.current
        )
      end
    end

    user
  end

  def full_name
    "#{first_name} #{last_name}".strip
  end
end
