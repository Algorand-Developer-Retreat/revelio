class Project < ApplicationRecord
  belongs_to :user
  has_many :contracts

  validates :name, presence: true
  validates :abbreviation, presence: true
  validates :verified, inclusion: { in: [true, false] } 
end
