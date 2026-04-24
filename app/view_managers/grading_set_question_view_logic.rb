module GradingSetQuestionViewLogic
  include CommonGradingViewLogic

  SKIP_NO_PROMPT_MESSAGE_TYPES = %w[
    column_matching
    image_choice
    drag_and_drop_fill_in_the_blanks
    word_ordering_v2
  ].freeze

  attr_accessor :presenter, :question
  delegate :prompt, :question_number, :to => :question

  def initialize(presenter, question)
    @presenter = presenter
    @question = question
  end

  def chat_activity?
    activity_partner_chat? || activity_virtual_chat? || activity_group_chat?
  end

  def solo_video_recording_activity?
    activity_solo_video_recording?
  end

  def question_label
    question.label
  end

  def audio_file_location
    question.prompt.audio.media_item.public_filename_for_arc
  end

  def server_url(request_url)
    question.prompt.audio.media_item.server_url(request_url)
  end

  def show_question_prompt?
    !chat_activity? && !table_activity? && !table_activity_question? && !activity_ai_virtual_chat?
  end

  def show_no_prompt_message?
    SKIP_NO_PROMPT_MESSAGE_TYPES.exclude?(activity.activity_type)
  end

  def has_prompt?
    question.respond_to?(:prompt) && question.prompt.present?
  end

  def text_prompt_content
    unless arc_activity?
      yield
    end
  end

  def sample_answer_content
    unless arc_activity?
      template = '/instructor/grading_sets/sample_answer'
      yield template
    end
  end

  def question_content_object
    if activity.has_sub_activities?
      current_sub_activity
    else
      activity.content_object
    end
  end

  def current_sub_activity
    sub_activity_and_rank_for_current_question[:sub_activity]
  end

  def sub_activity_and_rank_for_current_question
    return @sub_activity_and_rank if @sub_activity_and_rank

    activity.sub_activities.each_with_index do |sub_activity, index|
      if sub_activity.items.include?(question)
        @sub_activity_and_rank = { rank: index + 1, sub_activity: }
      end
    end
    @sub_activity_and_rank
  end
end
