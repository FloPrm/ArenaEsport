class Feedback < ApplicationRecord
  belongs_to :mentorat
  belongs_to :mentor
  belongs_to :user
end
