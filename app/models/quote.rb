class Quote < ApplicationRecord
  belongs_to :user

  # Validation
  validates_presence_of :user_id

  validates :quotation, presence: true,
                        length: { maximum: 255 }

  validates :source, presence: true,
                     length: { maximum: 255 }
end
