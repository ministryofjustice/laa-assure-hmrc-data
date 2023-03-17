class User < ApplicationRecord
  # Include default devise modules.
  # Common modules are:
  # :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable
  # Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable

  # devise :omniauthable , omniauth_providers: [:azure_ad]
end
