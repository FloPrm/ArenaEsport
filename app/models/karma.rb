class Karma < ApplicationRecord
  belongs_to :voter, :class_name => "User", inverse_of: :given_karmas
  belongs_to :voted, :class_name => "User", inverse_of: :received_karmas

  self.per_page = 100
end
