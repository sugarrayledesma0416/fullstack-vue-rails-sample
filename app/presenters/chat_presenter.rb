class ChatPresenter
  delegate :chat_section_id, :chat_permissions, to: :@permit

  def initialize(permit)
    @permit = permit
  end

  def chat_course_id_or_undefined
    @permit.chat_course_id || 'undefined'
  end
end
