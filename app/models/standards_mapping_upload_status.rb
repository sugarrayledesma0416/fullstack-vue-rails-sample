class StandardsMappingUploadStatus < ApplicationRecord
  # return the latest successful processing record
  # for the specified index
  def self.last_successful_upload_date(index_name)
    StandardsMappingUploadStatus.where(index_name: index_name, successful: true).order('uploaded_at_date DESC').first&.uploaded_at_date
  end
end
