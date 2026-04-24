class Instructor::InstructorResourceSettingsController < RequireInstructorController
  include ResourceHelper
  skip_before_action :set_current_program,
                     :set_current_focus,
                     :assign_course_sections_and_students_from_focus

  def create
    @instructor_resource_setting = InstructorResourceSetting.new
    prepare_new_resource_setting
    remove_old_resource_settings

    if @instructor_resource_setting.save
      render 'create', formats: [:js]
    else
      respond_to do |format|
        format.js do
          render plain: 'Could not create setting for this resource', status: 500
        end
      end
    end
  end

  def update_many
    successful_resources = []
    failed_resources = []
    protected_resources = []
    selected_resources_ids = params[:selected_resources].split(',')
    instructor_setting_status = params[:instructor_setting_status]

    user = User.find(params[:user_id])
    resources = Resource.where(id: selected_resources_ids)

    resources.each do |resource|
      if resource.protected?
        protected_resources << resource
        next
      end

      updater = ResourceUpdater.new(
        user,
        { resource: {}, resource_student_visibility: (instructor_setting_status == 'shown').to_s },
        resource
      ).update

      if updater.successful?
        successful_resources << resource.id
      else
        failed_resources << resource.id
      end
    end

    respond_to do |format|
      format.js do
        warning_message = error_message_for_protected_resources(protected_resources)
        error_message = error_message_for_failed_resources(failed_resources)
        friendly_label = InstructorResourceSetting::FRIENDLY_LABELS[instructor_setting_status]
        json_params = {
          error_message:,
          friendly_label:,
          instructor_setting_status:,
          successful_resources:,
          warning_message:
        }

        if failed_resources.present?
          render json: json_params, status: :internal_server_error
        elsif protected_resources.present?
          render json: json_params, status: :unprocessable_entity
        else
          render json: json_params, status: :ok
        end
      end
    end
  end

  private

  def remove_old_resource_settings
    @instructor_resource_setting.destroy_old_settings
  end

  def prepare_new_resource_setting
    @instructor_resource_setting.user_id = params[:user_id]
    @instructor_resource_setting.resource_id = params[:resource_id]
    @instructor_resource_setting.student_visibility = 'shown'
  end
end
