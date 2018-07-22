class Wallet < ApplicationRecord
  belongs_to :user
  has_many :wallet_histories, dependent: :destroy
end
