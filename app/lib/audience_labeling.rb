module AudienceLabeling
  DICTIONARY = {
    default: {
      Instructor_graded: 'Instructor-graded',
      instructor: 'instructor',
      Instructor: 'Instructor',
      student: 'student'
    },
    elementary: {
      Instructor_graded: 'Teacher-graded',
      instructor: 'teacher',
      Instructor: 'Teacher'
    }
  }.freeze

  def audience_label(audience, key)
    DICTIONARY.dig(audience, key) || DICTIONARY.dig(:default, key)
  end
end
