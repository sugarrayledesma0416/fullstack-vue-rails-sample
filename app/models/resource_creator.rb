class ResourceCreator
  include CommonResourceSavingMethods
  include Uploadable::Controller
  include FileTypeParsable

  attr_accessor :user, :params, :resource, :instructor_resource_setting, :successful
  attr_reader :detected_virus_name

  def initialize(user, params)
    self.user = user
    self.params = params || {}
    self.successful = false
  end

  def create
    self.resource = Resource.new(resource_params)
    # check_successful
    if self.successful = save_successful
      resource.upload_file(params[:uploaded_file])
      create_instructor_resource_setting
    end
    self
  end

  def resource_params
    params[:resource] ||= {}
    params[:resource].merge( owner_params ).
      merge(:program_id => params[:program_id]).
      merge( unit_params ).
      merge( uploaded_file_params )
  end
  private :resource_params

  def owner_params
    if user.is_resource_editor?
      { :source   => 'VHL',
        :uploaded => false,
        :vhl_student_resource => visible_to_students?,
        :owner_id => nil    }
    else
      { :source   => 'Instructor',
        :uploaded => true,
        :owner_id => user.id }
    end
  end
  private :owner_params

  def update_resource_attributes
    resource.save
  end

end
