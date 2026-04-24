class WorksetsController < ApplicationController
  before_action :require_user
  before_action :require_program_access

  def show
    @section = Section.find(params[:section_id])
    @assignment_day = params[:assignment_day]
    @concept = Concept.find_by(id: params[:concept_id])
    @category = Category.find_by(id: params[:category_id])

    # To create workset, find all assignments for this section and day.
    # If a concept is specified, limit to assignments for this concept.
    @classwork = Classwork.new(current_user, @section)
    classwork_filter = ClassworkFilter.new(
      assignment_day: @assignment_day,
      category: @category,
      classwork: @classwork,
      concept: @concept,
      include_all_assignments: params[:full],
      lesson_id: params[:lesson_id],
      rank_range: params[:rank_range]
    )

    if classwork_filter.has_assignments?
      classwork_filter.create_workset
      redirect_to(
        section_activity_path(
          @section,
          classwork_filter.first_activity_for_student(current_user)
        )
      )
    elsif supersite_junior?
      render(:supersite_junior_no_assignments, layout: 'music_v1/default')
    else
      # if no assignments, show nice error
      render(:no_assignments)
    end
  end
end
