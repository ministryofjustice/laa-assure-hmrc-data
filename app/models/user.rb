class User < ApplicationRecord
  # Include default devise modules.
  # Common modules are:
  # :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable
  # Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable

  devise :omniauthable , omniauth_providers: [:azure_ad]

  def self.from_omniauth(auth)
    user = find_by(auth_subject_id: auth.uid) || find_by(email: auth.info.email, provider: auth.provider)

    if user
      user.update!(auth_subject_id: auth.uid, auth_last_sign_in_at: Time.current)
    end

    user
  end

  def full_name
    "#{first_name} #{last_name}".strip.titleize
  end
end
