class Vote < ApplicationRecord
  belongs_to :team
  belongs_to :votable, polymorphic: true
end
