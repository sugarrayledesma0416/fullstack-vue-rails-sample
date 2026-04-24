#  encoding: utf-8

class CompositionAttacher

  include Uploadable::Controller

  attr_accessor :user, :section, :uploaded_file_param, :error, :attachment, :previous_attachment_id
  attr_writer :successful

  def initialize(user, section, uploaded_file_param, previous_attachment_id = nil)
    self.user = user
    self.section = section
    self.uploaded_file_param = uploaded_file_param
    self.previous_attachment_id = previous_attachment_id
    self.successful = true
  end

  def upload
    validate_file_specified
    process_virus_scan
    create_composition_attachment
  end

  def response
    {:success => successful?}.tap do |hash|
      if error.present?
        hash[:reason] = error
      else
        hash[:attachment_id] = attachment.id
        hash[:download_url] = "/sections/#{section.id}/composition_attachments/#{attachment.id}"
      end
    end
  end

  def create_composition_attachment
    return unless successful?
    params = {:user => user, :file => uploaded_file_param}
    self.attachment = CompositionAttachment.create(params)
    if attachment.errors.any?
      fail_with_error_message( attachment.errors.full_messages )
    elsif previous_attachment_id
      process_previous_attachment
    end
  end
  private :create_composition_attachment

  def active_record_errors_to_text
    attachment.errors.full_messages.each do |message|
      if message.include? "You tried to upload a file with extension"
      end
    end
    attachment.errors.full_messages.join("<br />")
  end
  private :active_record_errors_to_text

  def process_virus_scan
    return unless successful?
    process_uploaded_file(uploaded_file_param, needs_filetype = false)
    unless upload_is_virus_free?
      fail_with_error_message(set_detected_virus_error_if_detected(error_type = :text))
    end
  end
  private :process_virus_scan

  def process_previous_attachment
    previous_attachment = CompositionAttachment.find_by_id(previous_attachment_id)
    return unless previous_attachment

    if previous_attachment.replaces_attachment_id?
      # if the attachment we are replacing is itself a replacement for something,
      # we can delete it, passing forward the id of the attachment that it replaced
      replaces_attachment_id = previous_attachment.replaces_attachment_id
      previous_attachment.destroy_by_user(user)
    else
      replaces_attachment_id = previous_attachment.id
    end
    attachment.update!(:replaces_attachment_id => replaces_attachment_id)
  end
  private :process_previous_attachment

  def successful?
    @successful
  end
  private :successful?

  def fail_with_error_message(message)
    self.error = [message].flatten
    self.successful = false
  end

  def validate_file_specified
    if uploaded_file_param.blank?
      fail_with_error_message "You should select a file to upload."
    end
  end
  private :validate_file_specified

end
