class StudentTocPresenter
  include ApplicationHelper
  include MultipleDueDatesChecker
  include Rails.application.routes.url_helpers
  # "Common" means shared between Supersite Junior and non-Supersite Junior
  include TocPresenterCommon
  # "Standard" means "not Supersite Junior"
  include StandardTocPresentation
  include StudentTocPresentation

  attr_accessor :course,
                :current_user,
                :section_id,
                :program,
                :section,
                :school

  def initialize(program,
                 student,
                 section,
                 req_params,
                 saved_location,
                 current_section_id)
    if !program || !current_section_id || !student || !req_params
      raise ArgumentError, "Invalid StudentTocPresenter parameters. Parameters given:" +
                            "\n#{[program, student, section, req_params, saved_location, current_section_id].map(&:inspect).join("\n\n")}"
    end

    self.current_user = student
    self.program = program
    self.section_id = current_section_id
    self.section = section
    self.course = section.course if section
    self.school = section.school if section && section.course
    @req_params = req_params
    @saved_location = saved_location
  end

  # used to find the strand_id for passing to the gradebook even when the
  # activity is in a substrand.
  # current_strand can't be used because it will return a substrand_id
  private def grading_strand
    display_lesson.extend(ParallelLocationFinding)
                  .most_relevant_strand(req_params[:toc_location],
                                        saved_location,
                                        find_substrand = false).location.to_s
  end

  def base_url(options={})
    section_toc_path(section_id,program.id,options)
  end

  def base_url_params
    {:section_id => section_id, :program_id => program.id}
  end

  def portfolio_enabled?(activity)
    course&.activity_share_to_portfolio?(
      activity.activity_type
    ) && access_guardian.has_portfolio?
  end
end
