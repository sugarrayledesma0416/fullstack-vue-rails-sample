class ActivitiesListController < ApplicationController
  include HttpBasicAuthHelper

  before_action :http_basic_authenticate

  ACTIVITY_COLUMNS = %i[
    activity_type assignment_group cms_activity_id cms_revision_id component_name
    icon id lesson_id license_group_id page title toc_location toc_location_rank
    concept_rank
  ].freeze

  # activities for a program
  def index
    pgm = Program.find(params[:program_id])
    lessons = pgm.lessons

    listing = lessons.each_with_object({}) do |lesson, memo|
      concept_ids = lesson.concepts.map(&:id)
      activities = concept_activities(concept_ids)
      concept_ids.each do |concept_id|
        memo[concept_id] = activities.select { |act| act.toc_location == concept_id.to_i }
      end
    end

    render json: listing

  rescue StandardError => e
    render json: { error: e.message }, status: 500
  end

  # activities for one concept
  def show
    activities = concept_activities(params[:concept_id])

    render json: activities
  end

  # assignment counts for phantom activities
  def current_assignment_count
    assignments = Assignment.where(assignable_type: 'Activity', assignable_id: params[:activity_ids])
                            .where('due_date > ?', Time.zone.today)
                            .group(:assignable_id)
                            .count
    render json: assignments
  end

  private def concept_activities(concept_id)
    Activity.select(ACTIVITY_COLUMNS)
            .includes(:lesson)
            .where(toc_location: concept_id, instructor_revision_id: nil)
            .order(:toc_location_rank)
  end
end
