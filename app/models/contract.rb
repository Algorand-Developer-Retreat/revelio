class Contract < ApplicationRecord
  belongs_to :project

  validates :name, presence: true
  validates :version, presence: true
  validates :round_valid_from, presence: true
  validates :app_id, presence: true
  validates :address, presence: true
end
