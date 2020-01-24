class User < ApplicationRecord
  has_one :setting, dependent: :destroy
  has_many :task_categories, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :quotes, dependent: :destroy

  attr_accessor :accepted_tos, :activation_token, :reset_token, :remember_token
  has_secure_password

  # Validation
  EMAIL_REGEX = /\A[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}\Z/i.freeze

  validates :first_name, presence: true,
                         length: { maximum: 50 }

  validates :last_name, presence: true,
                        length: { maximum: 50 }

  validates :email, presence: true,
                    length: { within: 3..255 },
                    format: EMAIL_REGEX,
                    uniqueness: { case_sensitive: false },
                    confirmation: true

  validates :password, presence: true, length: { minimum: 10 }, allow_nil: true
  validates :accepted_tos, acceptance: true

  # Make it easier to prevent email duplicates by downcasing them by default:
  before_save   :downcase_email
  before_create :create_activation_digest
  after_create  :create_user_settings, :create_default_task_category

  # Returns the hash digest of the given string
  def self.digest(string)
    # rubocop:disable Layout/LineLength
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    # rubocop:enable Layout/LineLength
    BCrypt::Password.create(string, cost: cost)
  end

  # Returns a random token
  def self.new_token
    SecureRandom.urlsafe_base64
  end

  # Remembers a user in the database for use in persistent sessions
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  # Returns true if the given token matches the digest
  def authenticated?(attribute, token)
    # self is implied with send here:
    digest = send("#{attribute}_digest")
    return false if digest.nil?

    BCrypt::Password.new(digest).is_password?(token)
  end

  # Forgets a user
  def forget
    update_attribute(:remember_digest, nil)
  end

  # Activates an account
  def activate
    update(activated: true, activated_at: Time.zone.now)
  end

  # Sends activation email
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
    # Log the ToS acceptance time
    self.accepted_tos_at = Time.zone.now
    save
  end

  # Re-sends activation email with a new link
  def resend_activation_email
    create_activation_digest
    save
    UserMailer.account_activation(self).deliver_now
  end

  # Sets the password reset attributes
  def create_reset_digest
    self.reset_token = User.new_token
    update(reset_digest: User.digest(reset_token), reset_sent_at: Time.zone.now)
  end

  # Sends password reset email
  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  # Returns true if a password reset has expired
  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  private

  # Returns email in all lowercase
  def downcase_email
    email.downcase!
  end

  # Creates and assigns the activation token and digest
  def create_activation_digest
    self.activation_token = User.new_token
    self.activation_digest = User.digest(activation_token)
  end

  # Ensure each User has an associated Setting object
  def create_user_settings
    self.setting = Setting.new
  end

  # Ensure each User has an 'Uncategorized' TaskCategory that will be used for
  # tasks where a TaskCategory is not set
  def create_default_task_category
    task_categories << TaskCategory.new(name: 'Uncategorized')
  end
end
