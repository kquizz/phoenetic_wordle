class Word < ApplicationRecord
  validates :text, presence: true, uniqueness: true
  validates :ipa, presence: true
  validates :phonemes, presence: true
  validates :phoneme_count, presence: true

  scope :five_phonemes, -> { where(phoneme_count: 5) }
end
