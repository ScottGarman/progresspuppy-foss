class Setting < ApplicationRecord
  belongs_to :user

  # Validation
  validates_presence_of :user_id
end
