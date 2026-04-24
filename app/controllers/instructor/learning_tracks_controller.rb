class Instructor::LearningTracksController < RequireInstructorController
  def external_items
    respond_to do |format|
      format.json do
        external_items = GradebookEngine::GradebookAPI.find_external_items_by_section(
          params[:section_id]
        )
        render json: external_items, root: false
      end
    end
  end

  def learning_tracks
    respond_to do |format|
      format.json do
        program = Program.find(params[:program_id])
        activity_exporter = LearningTrack::ActivityExporter.new(program)
        render json: activity_exporter.activities_json
      end
    end
  end

  def section_learning_track
    previous_course_packages = Maestro::CoursePackage.all_for_course(previous_section.course.guid)
    current_course_id = params[:current_course_id]
    track = SectionLearningTrack.new(previous_section, previous_course_packages, current_course_id)
    render json: track, serializer: SectionLearningTrackSerializer, root: false
  end

  def previous_section
    @previous_section ||= Section.including_enterprise.find(params[:section_id])
  end
end
