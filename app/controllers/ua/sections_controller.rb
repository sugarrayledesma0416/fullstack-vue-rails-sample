module Ua
  class SectionsController < ActiveResourceController
    before_action :require_section

    def update
      if section.update(section_instructors_attributes: converted_attrs(section))
        render json: section
      else
        render json: section.errors, status: :unprocessable_entity
      end
    end

    def add_section_instructor
      section_instructors = add_section_instructors_attributes.filter_map do |attrs|
        # Only create a record if it does not yet exist
        SectionInstructor.new(attrs) unless SectionInstructor.where(attrs).exists?
      end
      begin
        SectionInstructor.transaction do
          section_instructors.each(&:save!)
        end

        render json: {}
      rescue ActiveRecord::RecordInvalid => e
        render_errors(
          [
            "Failed to create section instructor (section_guid #{section.guid}, " \
            "user_guid #{e.record.instructor.guid}, role #{e.record.role}): " \
            "#{e.record.errors.full_messages.join(',')}"
          ]
        )
      end
    end

    def remove_section_instructor
      SectionInstructor
        .joins(:instructor)
        .where(
          section_id: section.id,
          users: { guid: remove_section_instructor_guids }
        ).destroy_all

      render json: {}
    end

    private def safe_add_section_instructors_params
      params.permit(:guid, section_instructors: %i[user_guid role])
    end

    private def add_section_instructors_attributes
      safe_add_section_instructors_params[:section_instructors].map do |attrs|
        instructor = Instructor.find_by(guid: attrs[:user_guid])
        attrs.slice(:role).merge(
          section_id: section.id,
          user_id: instructor&.id
        )
      end
    end

    private def safe_remove_section_instructors_params
      params.permit(:guid, section_instructors: %i[user_guid])
    end

    private def remove_section_instructor_guids
      safe_remove_section_instructors_params[:section_instructors].map do |attrs|
        attrs[:user_guid]
      end
    end

    private def require_section
      unless section
        render(
          json: { message: "Section with guid #{params[:guid]} not found" },
          status: :not_found
        )
        false
      end
    end

    private def section
      return @section if defined? @section

      @section = ::Section.find_by(guid: params[:guid])
    end

    private def safe_params_hash
      params.permit(
        :guid,
        section_instructors_attributes: %i[
          user_guid
          role
        ]
      )
    end

    # Convert guids to m3 ids in the section_instructor_attributes.
    private def converted_attrs(section)
      safe_params_hash[:section_instructors_attributes].map do |attrs|
        instructor = Instructor.find_by(guid: attrs[:user_guid])
        attrs.slice(:role).merge(
          section_id: section.id,
          user_id: instructor&.id
        )
      end
    end

    private def render_errors(errors)
      render json: { errors: errors }, status: :unprocessable_entity
    end
  end
end
