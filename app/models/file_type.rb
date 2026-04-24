class FileType < ApplicationRecord
  default_scope { order('extension_name ASC') }

  scope :allowed, -> { where(is_allowed: true) }
end
