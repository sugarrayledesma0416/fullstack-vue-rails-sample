class GradingFeedback

  def initialize(params)
    @students = params[:students]
    @questions = params[:questions]
    @sections = params[:sections]
    @activity = params[:activity]
  end

  def [](key)
    label, student = response_id_to_label_and_student(key)
    question_feedback(student, label) if label && student
  end

  def feedback_items
    unless @feedback_items
      @feedback_items = FeedbackItem.by_attempts(attempts.map(&:id))
    end
    @feedback_items
  end

  def attempts
    @attempts ||= Attempt.activity_attempts(@sections, @students, @activity)
  end

  def attempt_for_student(student)
    attempts.detect { |attempt| attempt.user_id == student.id }
  end

  def general_feedback(student)
    feedback_items.detect { |fb| item_matches?(fb, student, nil) }
  end

  def question_feedback(student, label, method = nil)
    item = feedback_items.detect { |fb| item_matches?(fb, student, label) }
    if item
      if method
        item.send(method)
      else
        item
      end
    end
  end

  def question_comment(student, label)
    question_feedback(student, label, :comment)
  end

  def question_markup(student, label)
    question_feedback(student, label, :inline_corrections)
  end

  def question_recording(student, label)
    question_feedback(student, label, :recording)
  end

  def question_points(student, label)
    question_feedback(student, label, :points_earned)
  end

  def item_matches?(item, student, label)
    item.user_id == student.id && item.question_label == label
  end
  private :item_matches?

  # key should be in the form "question_01_student_456"
  # the first part will correspond to the question label
  # with the number on the end being the student_id
  def response_id_to_label_and_student(key)
    reg = Regexp.new(/(.*)_student_(\d+)/)
    matches = reg.match(key)
    if matches.present?
      label = matches[1]
      if @students.is_a?(Student)
        student = ( @students.id == matches[2].to_i ? @students : nil )
      else
        student = @students.detect { |student| student.id == matches[2].to_i }
      end
    end
    [label, student]
  end
  private :response_id_to_label_and_student

end
