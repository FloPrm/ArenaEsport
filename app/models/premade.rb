class Premade < ApplicationRecord
  belongs_to :user1, :class_name => "GameAccount", foreign_key: :user1
  belongs_to :user2, :class_name => "GameAccount", foreign_key: :user2
  belongs_to :user3, :class_name => "GameAccount", foreign_key: :user3

  def users
    ([self.user1] + [self.user2] + [self.user3]).reject(&:nil?)
  end
end
