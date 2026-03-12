class Role < ApplicationRecord
  BASE_ROLES = %w[admin teacher student].freeze

  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  validates :name, presence: true, uniqueness: true
end
