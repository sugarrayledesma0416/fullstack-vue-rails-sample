
class UnprocessedRequestCounter
  # Generates counts of unprocessed help_request records, broken out by section and request_type
  # to be used on the instructor dashboard.

  attr_accessor :students, :sections, :student_counts, :request_counts

  def initialize(sections, students)
    self.students = students
    self.sections = sections
  end

  def populate
    populate_student_counts
    populate_request_counts
    self
  end

  def needy_student_count(section_id)
    student_counts[section_id] || 0
  end

  def help_request_count(section_id)
    request_count_for('request_help', section_id)
  end

  def review_request_count(section_id)
    request_count_for('request_review', section_id)
  end

  def target_request_types
    %w(request_help request_review)
  end
  private :target_request_types

  def request_count_for(request_type, section_id)
    request_counts[[request_type, section_id]] || 0
  end
  private :request_count_for

  def populate_student_counts
    count_opts = { select: 'distinct help_requests.user_id', group: 'help_requests.section_id' }
    self.student_counts = count_unprocessed(count_opts)
  end
  private :populate_student_counts

  def populate_request_counts
    count_opts = { group: [:request_type, 'help_requests.section_id'] }
    self.request_counts = count_unprocessed(count_opts)
  end
  private :populate_request_counts

  def count_unprocessed(count_opts)
    HelpRequest.count_unprocessed_by_request_type_section_and_students(target_request_types, sections, students, count_opts)
  end
  private :count_unprocessed

end
