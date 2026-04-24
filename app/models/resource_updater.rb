class ResourceUpdater
  include CommonResourceSavingMethods
  include Uploadable::Controller
  include FileTypeParsable

  attr_accessor :user, :params, :resource, :successful
  attr_reader :detected_virus_name

  def initialize(user, params, received_resource)
    @user = user
    @params = params
    @resource = received_resource
    @successful = false
  end

  def update
    params[:resource].merge!(unit_params)
    set_file_params
    # Backup of current file name in case we need to revert.
    file_name = current_file_name
    old_file = old_file_path
    if self.successful = save_successful
      swap_files(old_file) if uploaded_file?
      update_instructor_resource_settings
    else
      # Undo!
      @resource.file_name = file_name
    end
    self
  end

  def old_file_path
    if needs_uploading? && uploaded_file?
      @resource.file_path
    else
      ''
    end
  end

  def current_file_name
    if needs_uploading? && !uploaded_file?
      @resource.file_name
    else
      ''
    end
  end

  def update_resource_attributes
    params[:resource][:vhl_student_resource] = visible_to_students? if user.is_resource_editor?
    @resource.update(params[:resource])
  end

  def swap_files(old_path)
    @resource.dispose_file old_path
    @resource.upload_file params[:uploaded_file]
  end

  def needs_uploading?
    params[:file_uploading] == 'needed'
  end

  def uploaded_file?
    params[:uploaded_file].present?
  end

  def set_file_params
    if needs_uploading?
      if uploaded_file?
        params[:resource].merge!(uploaded_file_params)
      else
        params[:resource][:file_name] = ""
      end
    end
  end
  private :set_file_params

  def update_instructor_resource_settings
    return if user.is_resource_editor?
    instructor_settings = InstructorResourceSetting.find_by_user_id_and_resource_id(user.id, @resource.id)
    if instructor_settings.present?
      update_student_visibility(instructor_settings)
    elsif visible_to_students?
      create_instructor_resource_setting
    end
  end

  def update_student_visibility(instructor_settings)
    visibility = visible_to_students? ? 'shown' : 'hidden'
    instructor_settings.update(:student_visibility => visibility)
  end
end
