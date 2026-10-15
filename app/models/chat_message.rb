class ChatMessage < ApplicationRecord
  # NOTE: Association with user
  belongs_to :user

  # IMPORTANT: Validations
  validates :content, presence: true, length: { maximum: 1000 }
  validates :user, presence: true

  # NOTE: Scope for ordering
  scope :recent, -> { order(created_at: :desc) }
  scope :chronological, -> { order(created_at: :asc) }
end