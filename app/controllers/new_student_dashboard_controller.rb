class NewStudentDashboardController < ApplicationController
  before_action :require_user

  def past_assignment_summaries
    @presenter = StudentDashboardPresenter.new(current_user, current_section)
    render(
      partial: 'sections/due_date_tabs',
      locals: {
        assignment_summaries: @presenter.past_assignment_summaries,
        presenter: @presenter
      }
    )
  end

  def assignments_by_due_date
    program_language = (code = current_program&.language_code) && code != 'zh' ? code : 'en'
    assignment_groups = DueDate.new(
      current_section.id, params[:due_date], current_user.id
    ).assignment_groups
    render(
      partial: 'sections/assignments_by_concepts',
      locals: {
        assignment_groups: assignment_groups,
        due_date: params[:due_date],
        program_language:
      }
    )
  end

  def assignments
    render json: StudentDashboardPresenter.new(
      current_user, current_section
    ).serialize_assignment_days.to_json
  end

  def progress
    rand = Random.new
    render json: {
      completion: { percentage: rand(1..100), hours: rand(1..100) },
      vocabulary: {
        words_mastered: rand(1..1000),
        time_left: rand(1..60),
        total_words: rand(1..1000),
        time_average: rand(1..100)
      }
    }.to_json
  end
end
