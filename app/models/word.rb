class Word < ApplicationRecord
  validates :text, presence: true, uniqueness: true
  validates :ipa, presence: true
  validates :phonemes, presence: true
  validates :phoneme_count, presence: true

  scope :five_phonemes, -> { where(phoneme_count: 5) }
  scope :with_phoneme_count, ->(n) { where(phoneme_count: n) }
  scope :common, -> { where(common: true) }

  ALLOWED_PHONEME_COUNTS = (2..8).freeze
  DEFAULT_PHONEME_COUNT = 3
end
