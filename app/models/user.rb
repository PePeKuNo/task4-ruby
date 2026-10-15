class User < ApplicationRecord
  # NOTE: has_secure_password provides password encryption using bcrypt
  # It requires password_digest column and adds authenticate method
  has_secure_password

  # IMPORTANT: Validations
  # Email must be present, unique (validated at model level too), and valid format
  # NOTA BENE: Database-level unique index is the ultimate guarantee (see migration)
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :full_name, presence: true
  validates :job_position, presence: true
  validates :status, presence: true, inclusion: { in: %w[active blocked] }
  # Password can be any non-empty string (requirement: "User can use any non-empty password")
  validates :password, presence: true, length: { minimum: 1 }, on: :create
  validates :password, length: { minimum: 1 }, allow_blank: true, on: :update

  # NOTE: Scopes for common queries
  scope :active, -> { where(status: 'active') }
  scope :blocked, -> { where(status: 'blocked') }
  scope :ordered_by_last_seen, -> { order(last_seen: :desc) }

  # NOTE: Instance methods for status checks
  def active?
    status == 'active'
  end

  def blocked?
    status == 'blocked'
  end

  # NOTE: Toggle methods for toolbar actions
  def block!
    update!(status: 'blocked')
  end

  def unblock!
    update!(status: 'active')
  end

  # NOTE: Update last_seen timestamp on activity
  def touch_last_seen!
    update!(last_seen: Time.current)
  end
end