module OneRoster
  module Instructor
    class CoursesController < RequireInstructorController
      def add; end

      def index
        @courses_presenter = CoursesPresenter.new(current_user)
        @roster_assistant_sections = @courses_presenter.roster_assistant_sections_group_by_status

        if @courses_presenter.client_last_request_successful?
          OneRoster::UnlinkedResource.new(
            sections: @roster_assistant_sections['available_sections'],
            user: current_user
          ).log_sections_without_school
        else
          if @courses_presenter.client_school_inactive?
            flash.now[:error] = 'Sorry, but we are unable to retrieve your courses from ' \
                                'Roster Assistant because your school is no longer active. ' \
                                'Please contact technical support for more information.'
          else
            flash.now[:error] = 'Sorry, but we are unable to retrieve your courses from ' \
                                'Roster Assistant at this time. Please try again later.'
          end
        end
      end

      def create
        errors = []
        notices = []
        new_sections = []
        if sections_to_create.present?
          sections_to_create.each do |course_section_data|
            creator = CourseSectionCreator.new(course_section_data, current_program, current_user)
            creator.create_course_and_section
            if (creator.errors.empty?)
              if (creator.section.present?)
                new_sections << { :section_guid => creator.section.guid,
                                  :external_class_id => creator.section.one_roster_linked_section.class_external_id }
              else
                errors += ['Error - neither course nor section created']
              end
            end
            errors += creator.errors
            notices += creator.notices
          end
        else
          errors << 'Please select a section.'
        end
        # UA will create enrollments for all the newly created sections
        begin
          Ua::OneRosterEnrollments.create(sections: new_sections) if new_sections.present?
        rescue ActiveResource::ServerError => e
          # nightly job will fixup the enrollments
          Rails.logger.warn "UA returned bad response: #{e.message} during enrollments creation for #{new_sections}"
         end
        redirect_path = if errors.blank? && notices.present?
                          instructor_dashboard_path(current_program)
                        else
                          flash[:error] = errors.join('<br/>')
                          one_roster_instructor_courses_path(program)
                        end
        flash[:notice] = notices.join('<br/>') if notices.present?
        redirect_to redirect_path
      end

      def destroy
        errors = []
        course = Course.find(params[:id])
        # RA created courses should only have one section.
        Course.transaction do
          course.sections.each do |section|
            section.archive
            errors += section.errors.full_messages if section.errors.present?
          end
          if errors.empty?
            course.reload
            course.archive
            errors += course.errors.full_messages if course.errors.present?
          end
        end
        if errors.empty?
          flash[:notice] = "Course <b>#{course.name}</b> and its sections were deleted successfully."
        else
          flash[:error] = errors.join('<br/>')
        end
        redirect_to instructor_dashboard_path(current_program)
      end

      private def sections_to_create
        @sections_to_create ||= params[:sections].select do |section|
          section_identifier = OneRoster::LinkedSection.build_identifier(section[:section][:course_external_id],
                                                                         section[:section][:class_external_id])
          params[:selected_sections]&.include?(section_identifier)
        end
      end
    end
  end
end
