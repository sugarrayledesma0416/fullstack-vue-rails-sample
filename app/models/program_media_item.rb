class ProgramMediaItem < ApplicationRecord
  belongs_to :program
  belongs_to :media_item

  LOGO_MEDIA_TYPE = 'logo'.freeze

  scope :logo, -> { where(media_type: LOGO_MEDIA_TYPE) }
end
