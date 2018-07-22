class Whitelist < ApplicationRecord
  before_save :downcase_email
  validates :email, presence: true

  self.per_page = 20

  def downcase_email
    self.email = email.downcase
  end
end
