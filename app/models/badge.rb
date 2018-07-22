class Badge < ApplicationRecord
  belongs_to :achievement

  validates :name, length: { maximum: 30 }
  validates :description, length: { maximum: 150 }
  validates :icon, length: { maximum: 50 }
  validates :icon_color, length: { maximum: 150 }
  validates :icon_style, length: { maximum: 150 }
  validates :bg, length: { maximum: 50 }
  validates :bg_color, length: { maximum: 100 }
end
