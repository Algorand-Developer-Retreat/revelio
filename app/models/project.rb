class Project < ApplicationRecord
  belongs_to :user
  has_many :contracts, dependent: :destroy
  has_one_attached :logo

  validates :name, presence: true
  validates :abbreviation, presence: true, uniqueness: true
  validates :verified, inclusion: { in: [true, false] }
  
  # Validate logo format and size
  # validates :logo, content_type: { in: ['image/png', 'image/jpeg', 'image/jpg', 'image/gif', 'image/svg+xml'], 
  #                                  message: 'must be a valid image format (PNG, JPEG, GIF, SVG)' },
  #                  size: { less_than: 2.megabytes, message: 'should be less than 2MB' },
  #                  allow_nil: true

  after_save :log_attributes

  private

  def log_attributes
    Rails.logger.debug "Project saved with attributes: #{attributes.inspect}"
  end
end
