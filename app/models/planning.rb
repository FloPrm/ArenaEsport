class Planning < ApplicationRecord
  belongs_to :user
  belongs_to :team

  STATES = {"t 'layout.present'" => 2, "t 'layout.not_sure'" => 1, "t 'layout.absent'" => 0}.freeze

end
