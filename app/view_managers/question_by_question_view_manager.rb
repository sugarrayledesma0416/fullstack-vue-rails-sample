class QuestionByQuestionViewManager
  include GradingSetQuestionViewLogic
  include StudentOrQuestionDropdownLogic
  include TableActivityLogic

  delegate :grading_set, :questions_to_grade, :disable_controls?,
           :students_to_grade, :students_graded, :students, :activity_composition?,
           :question_to_grade_view_manager, :student_attempt, :to => :presenter

  alias_method :current_question, :question

  def initialize(presenter)
    super(presenter, presenter.current_question)
  end

  def students
    if question.is_a?(Smartbook::Response)
      presenter.students.select do |student|
        # Do not show student answer for unsubmitted questions
        results(student).has_response?(question.label)
      end
    else
      presenter.students
    end
  end

  def language
    activity.content_object.language
  end

  def currently_on_first_question?
    current_question == questions_to_grade.first
  end

  def currently_on_last_question?
    current_question == questions_to_grade.last
  end

  def current?(question)
    current_question == question
  end

  def results(student)
    student_attempt(student).results
  end

  def true_false_enhanced_correction(student)
    results(student).chosen("#{question_label}_correction")
  end

  def html_friendly_prompt
    #The do block for html_friendly_prompt below is only evaluated if the definition of html_friendly_prompt in the MaestroActivityEngine::ActivityContent::SomeClass::Item
    #accepts a block. So for example, the block will not get evaluated in the MaestroActivityEngine::ActivityContent::OpenEnded::Item definition
    #of html_friendly_prompt, but it will get evaluated in MaestroActivityEngine::ActivityContent::FillInTheBlanks::Item definition of html_friendly_prompt.
    #This allows us to use this method for all types of activities (auto-graded, instructor graded, multi-type...)
    #
    #The yield for format_reference_diagnostic and for format_reference is there for delayed evaluation.
    #Since we are in a view manager, we cannot call render and other methods used in view (which are being used in format_reference
    #and format_reference_diagnostic), so we delay the evaluation of them, and in the view, we do:
    #
    #<% work_presenter.html_friendly_prompt do |formatter, *args| %>
    #  <%= self.send(formatter, *args) %>
    #<% end %>
    #
    if activity.has_mixed_grading_method? && question.is_a?(MaestroActivityEngine::ActivityContent::OpenEnded::Item) && current_sub_activity.diagnostic_reference.present?
      #this is a fix for open ended DL's not showing up when viewing a multi-type with an open ended question in question by question mode
      yield :format_reference_diagnostic, current_sub_activity.activity_type,
                                          current_sub_activity.diagnostic_reference,
                                          current_sub_activity_rank,
                                          nil,
                                          current_sub_activity.is_bonus,
                                          true
    else
      question.html_friendly_prompt do
        if activity.has_mixed_grading_method?
          if current_sub_activity.diagnostic_reference.present?
            yield :format_reference_diagnostic, current_sub_activity.activity_type,
                                                current_sub_activity.diagnostic_reference,
                                                current_sub_activity_rank,
                                                nil,
                                                current_sub_activity.is_bonus,
                                                true
          end
        else
          #TODO need to get this dl to render in the view!
          activity.content_object.dl.children.to_html.html_safe if activity.content_object.dl&.children
          reference = activity.content_object.items.detect{ |item| item.is_a?(MaestroActivityEngine::ActivityContent::Reference::Base) }
          yield :format_reference, reference
        end
      end
    end
  end

  def graded?(question)
    if inline_open_ended_table_question?(question)
      question.wols.all? do |wol|
        grading_status[wol.label] && grading_status[wol.label][:status_class] == 'complete'
      end
    else
      grading_status[question.label][:status_class] == 'complete'
    end
  end

  def current_sub_activity_rank
    sub_activity_and_rank_for_current_question[:rank]
  end
  private :current_sub_activity_rank

  def [](attr)
    question_title_text[attr]
  end

  def question_title_text
    if activity.has_mixed_grading_method?
      multi_type_question_text(activity)
    else
      single_type_question_text(activity)
    end
  end

  def column_matching_question?
    question.is_a?(MaestroActivityEngine::ActivityContent::ColumnMatching::Item)
  end

  def solo_video_recording_question?
    question.is_a?(MaestroActivityEngine::ActivityContent::SoloVideoRecording::Item)
  end

  def option_string(question)
    question.label
  end

  alias_method :option_value, :option_string

  alias_method :option_jump_to, :option_string

  def option_data(question)
    { question_label: question.label }
  end

  private def single_type_question_text(activity)
    presenter.activity_questions.each_with_object({}) do |question, memo|
      memo[question.label] = "Question #{question.question_number}"
    end
  end

  def multi_type_question_text(activity)
    activity.sub_activities.each_with_index.inject({}) do |memo, (sub_activity, index) |
      questions = questions_without_references(sub_activity.items)
      questions.each do |item|
        memo[item.label] = formatted_question_text(questions, item, index)
      end
      memo
    end
  end
  private :multi_type_question_text

  def questions_without_references(items)
    items.reject{|item| item.is_a?(MaestroActivityEngine::ActivityContent::Reference::Base) }
  end
  private :questions_without_references

  def formatted_question_text(questions, item, index)
    if questions.count == 1
      "Question #{index + 1}"
    else
      "Question #{index + 1} - #{item.question_number}"
    end
  end
  private :formatted_question_text
end
