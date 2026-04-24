module Ua
  module Lti
    class LaunchesController < ActiveResourceController
      before_action :require_lti_rostering_instructor

      REQUIRED_PARAMS = %i[
        context_id
        lti_platform_guid
        user_guid
      ].freeze

      REQUIRED_CREATE_PARAMS = %i[
        program_id
        school_guid
      ].freeze

      # section_guid is passed when UA has an active linked section
      OPTIONAL_PARAMS = %i[
        context_label
        context_title
        course_end_date
        course_start_date
        section_guid
      ].freeze

      def context
        @allowed_params = safe_params(REQUIRED_PARAMS + REQUIRED_CREATE_PARAMS)
        course_section_creator = ::Lti::CourseSectionCreator.new(
          @allowed_params,
          @user,
          @allowed_params[:program_id]
        )
        course_section_creator.process
        if course_section_creator.success
          # hand off back to UA to add the lti_context_link and enroll the students
          render_success(course_section_creator.section.guid)
        else
          # return error messages to UA to display - have to think about formatting for this.
          render_errors(course_section_creator.errors)
        end
      rescue  ActionController::ParameterMissing => e
        render_errors([e.original_message])
      end

      def destroy
        @allowed_params = safe_params(REQUIRED_PARAMS)
        lti_platform = ::Lti::Platform.find_by!(guid: @allowed_params[:lti_platform_guid])
        context_link = ::Lti::ContextLink.find_by!(
          context_id: @allowed_params[:context_id],
          lti_platform_id: lti_platform.id
        )
        section_guid = context_link.section.guid
        section_archiver = SectionArchiver.new
        if section_archiver.archive(context_link.section)
          render_success(section_guid)
        else
          render_errors([section_archiver.error_message])
        end
      rescue ActionController::ParameterMissing => e
        render_errors([e.original_message])
      rescue ActiveRecord::RecordNotFound => e
        render_errors([e])
      end

      private def lti_rostering_instructor?
        @user = Instructor.find_by(guid: @allowed_params[:user_guid])
        @user&.lti_rostering?
      end

      private def safe_params(required_params)
        params.require(required_params)
        params.slice(*(required_params + OPTIONAL_PARAMS))
      end

      private def render_errors(errors)
        render json:  { errors: errors }, status: :unprocessable_entity
      end

      private def render_success(section_guid)
        render json: { section_guid: section_guid }, status: :ok
      end

      private def require_lti_rostering_instructor
        @user = User.find_by!(guid: params[:user_guid])
        unless @user.instructor? && @user.lti_rostering?
          render_errors(["User guid: #{params[:user_guid]} is not an LTI Rostering instructor"])
        end
      rescue ActiveRecord::RecordNotFound
        render_errors(["User guid: #{params[:user_guid]} was not found"])
      end
    end
  end
end
