class User < ApplicationRecord
  include Discard::Model

  encrypts :auth_subject_uid, deterministic: true

  devise :timeoutable,
         :trackable,
         :omniauthable, omniauth_providers: [:azure_ad]

  has_many :bulk_submissions, dependent: :nullify

  def self.from_omniauth(auth)
    user = find_by(auth_subject_uid: auth.uid)

    if user
      user.update!(last_sign_in_at: Time.current)
    else
      user = find_by(email: auth.info.email, auth_provider: auth.provider, auth_subject_uid: nil)

      if user
        user.update!(
          auth_subject_uid: auth.uid,
          first_name: auth.info.first_name,
          last_name: auth.info.last_name,
          last_sign_in_at: Time.current,
        )
      end
    end

    user
  end

  def full_name
    "#{first_name} #{last_name}".strip
  end
end
