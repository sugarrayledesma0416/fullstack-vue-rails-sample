class InstructorHelpRequestsPresenter
  attr_accessor :activity_ids, :lists, :sections, :students

  def initialize(sections, students)
    self.sections = sections
    self.students = students
    self.activity_ids = []
    self.lists = {
      processed_help_requests: ConceptGroupList.new,
      unprocessed_help_requests: ConceptGroupList.new,
      processed_review_requests: ConceptGroupList.new,
      unprocessed_review_requests: ConceptGroupList.new
    }
  end

  module PresentableRequest
    # We're keeping this stuff here instead of adding complexity to the help
    # request model because this is, so far, the only place we need this, and
    # we don't want the help request model to get cluttered up with delegate
    # calls.  Here, we're pre-fetching the associated data, so these delegates
    # won't inflate the query count.
    delegate :concept, :title, :icon, to: :activity, prefix: true
    attr_accessor :student

    def list_type
      label_for_request_type = (
        request_type == 'request_help' ? 'help_requests' : 'review_requests'
      )
      label_for_processed = processed? ? 'processed' : 'unprocessed'
      "#{label_for_processed}_#{label_for_request_type}".to_sym
    end
  end

  def populate
    help_requests.each do |help_request|
      help_request.extend PresentableRequest
      activity_ids << help_request.activity_id
      help_request.student = students_by_id[help_request.user_id]
      list_for(help_request.list_type) << help_request
    end
    self
  end

  def help_requests
    HelpRequest.instructor_respondable_by_user_and_section(
      students, sections
    ).include_location
  end
  private :help_requests

  def request_count_for(list_id)
    lists[list_id].request_count
  end

  def concept_groups_for(list_id)
    lists[list_id].concept_groups
  end

  def list_for(list_type)
    lists[list_type]
  end
  private :list_for

  def students_by_id
    @students_by_id ||= students.index_by(&:id)
  end
  private :students_by_id

  # Common logic to faciliate nested grouping of help requests.
  module SubGroupable
    attr_accessor :subgroups_by_id

    def initialize
      self.subgroups_by_id = {}
    end

    # The container class for the objects that we are grouping on.
    # Each instance of the class corresponds to a unique instance of the
    # subobject.  Additional help requests that share the same subobject id
    # will get appended to the container instance.
    # e.g., if 2 help requests have the same activity_id, when the first one
    # is added, we'll create a new ActivityGroup class, passing the activity.
    # When the second one is added, we'll find the ActivityGroup
    # based on the activity_id, and append the help request to that group.
    def subgroup_class
      raise NotImplementedError,
            'Classes that include SubGroupable must def subgroup_class'
    end

    # Which attribute of the help_request will be used to identify the object
    # we want to group on.
    def subobject_attribute
      raise NotImplementedError,
            'Classes that include SubGroupable must def subobject_attribute'
    end

    def <<(help_request)
      # We'll be sending an attribute name to get the instance of the object
      # we want to group on. e.g. To group by activity, we'll call
      # help_request.send(:activity)
      # Grabbing the object instead of just the id because we actually want
      # to pass one instance of the object into the first instance of the
      # container class.
      subobject = help_request.send(subobject_attribute)

      # If there isn't already a container class corresponding to the id of
      # that object, we create one, passing the object in.
      # We then add the help request to the container class.
      subgroups_by_id[subobject.id] ||= subgroup_class.new(subobject)
      subgroups_by_id[subobject.id] << help_request
    end
  end

  class ConceptGroupList
    include SubGroupable

    attr_accessor :request_count

    def initialize
      super
      self.request_count = 0
    end

    def subgroup_class
      ConceptGroup
    end

    def subobject_attribute
      :activity_concept
    end

    def <<(help_request)
      super
      self.request_count += 1
    end

    def concept_groups
      subgroups_by_id.values.sort_by(&:concept_combined_rank)
    end
  end

  class ConceptGroup
    include SubGroupable

    attr_accessor :concept
    delegate :id, :name, :rank, :background_color, :lesson_combined_rank,
             :lesson_display_name, :concept_combined_rank, to: :concept

    def initialize(concept)
      self.concept = concept
      # the module's initialize method doesn't need the concept, so don't
      # pass it along
      super()
    end

    def subgroup_class
      ActivityGroup
    end

    def subobject_attribute
      :activity
    end

    def activity_groups
      subgroups_by_id.values.sort_by(&:toc_location_rank)
    end
  end

  class ActivityGroup
    include SubGroupable

    attr_accessor :activity
    delegate :id, :icon, to: :activity

    # Set an aribtrarily high rank for activities that have no toc_location_rank
    # e.g. Unlisted activities from diagnostics, so they appear at the end of the
    # list
    MAX_RANK = 9999

    def initialize(activity)
      self.activity = activity
      # the module's initialize method doesn't need the activity, so
      # don't pass it along
      super()
    end

    def toc_location_rank
      activity.toc_location_rank || MAX_RANK
    end

    def title
      # for some reason, delegate isn't working right for this attribute.
      # Maybe due to the weird way that it's defined in the model.
      activity.title
    end

    def subgroup_class
      StudentGroup
    end

    def subobject_attribute
      :student
    end

    def student_groups
      subgroups_by_id.values.sort_by(&:full_name)
    end

    def due_date
      # This will eventually get populated with assignment data
      ''
    end
  end

  class StudentGroup
    attr_accessor :student, :count, :section_id, :request_type
    delegate :id, :full_name, to: :student, allow_nil: true

    def initialize(student)
      self.count = 0
      self.student = student
    end

    # We're defining this method to keep the interface consistent with the
    # other classes that get defined as subgroup classes, but we don't really
    # need to do anything with the help request at this point.
    def <<(help_request)
      self.count += 1
      self.section_id ||= help_request.section_id
      self.request_type = help_request.request_type
    end
  end
end
