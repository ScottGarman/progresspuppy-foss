class TaskCategory < ApplicationRecord
  has_many :tasks
  belongs_to :user

  # Validation
  validates_presence_of :user_id

  validates :name, presence: true,
                   length: { maximum: 50 },
                   uniqueness: { scope: :user_id }
end
