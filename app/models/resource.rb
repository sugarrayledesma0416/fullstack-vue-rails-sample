class Resource < ApplicationRecord
  include ResourceVisibility
  include Radner::FilesS3Bucket

  default_scope { where(is_archived: false) }

  belongs_to :unit, foreign_key: :start_unit_id, optional: true
  belongs_to :lesson, optional: true
  belongs_to :program
  belongs_to :resource_component
  belongs_to :owner, class_name: 'Instructor', optional: true
  has_many   :instructor_resource_settings
  has_many   :assignments, as: :assignable

  alias_attribute :first_chapter, :start_unit_id
  alias_attribute :first_lesson, :start_unit_id
  alias_attribute :first_unit, :start_unit_id
  alias_attribute :first_section, :start_unit_id
  alias_attribute :first_theme, :start_unit_id
  alias_attribute :first_module, :start_unit_id
  alias_attribute :last_lesson, :end_unit_id
  alias_attribute :last_chapter, :end_unit_id
  alias_attribute :last_unit, :end_unit_id
  alias_attribute :last_section, :end_unit_id
  alias_attribute :last_theme, :end_unit_id
  alias_attribute :last_module, :end_unit_id
  validates_presence_of :title, message: 'is required.'
  validates_presence_of :file_name, message: 'is required.'

  validate :validate_units

  before_save :sanitize_file_name

  scope :by_file_type, ->(*file_type) { where(file_type: file_type) }
  scope :by_source, ->(*source) { where(source: source) }
  scope :by_program, ->(*program) { includes(:resource_component).where(program_id: program, is_archived: false) }
  scope :multi_unit, -> { where(['start_unit_id IS NOT NULL AND end_unit_id IS NOT NULL']) }
  scope :vhl_resource_or_uploaded_by_user, lambda { |user|
    where(["(uploaded = ? OR (uploaded = ? AND owner_id = ?))", false, true, user])
  }
  scope :by_component, ->(component_id) { where(resource_component_id: component_id) }
  scope :visible_to_students, -> { where(vhl_student_resource: true) }
  scope :by_lesson, ->(*lesson) { where(lesson_id: lesson) }

  delegate :unit_label, to: :program, allow_nil: true

  # Here are the rules:
  # 1) vhl_student_resource is true and there is no instructor
  # setting / the instructor has marked it as shown
  # 2) vhl_student_resource is false but the instructor has marked it as shown
  # 3) we don't care about vhl_student_resource or settings;
  # all we care is that it is assigned
  #
  # This should never be used on its own -- anything that
  # uses it is should specify a key of
  # :select => 'resources.*' plus whatever else is needed.
  # Leaving the :select key here can clobber more
  # explicit selects down the line.
  scope :visible_by_instructor, lambda { |instructor, section|
    joins(sanitize_sql_array(["LEFT OUTER JOIN instructor_resource_settings
                                       ON resources.id = instructor_resource_settings.resource_id
                                       AND instructor_resource_settings.user_id = ?
                                     LEFT OUTER JOIN assignments
                                       ON resources.id = assignments.assignable_id
                                       AND assignments.assignable_type = 'Resource'
                                       AND assignments.section_id = ?", instructor.id, section.id]))
      .where(["(resources.vhl_student_resource = :true
                       AND (instructor_resource_settings.id IS NULL OR instructor_resource_settings.student_visibility <> :hidden))
                       OR (resources.vhl_student_resource = :false AND instructor_resource_settings.student_visibility = :shown)
                       OR (assignments.id IS NOT NULL)",
                       { true: true, hidden: InstructorResourceSetting.settings[:hidden],
                         false: false, shown: InstructorResourceSetting.settings[:shown] }]) }

  scope :unprotected, -> { where(protected: false) }
  scope :sorted_by_unit_rank, lambda {
    includes(:resource_component)
      .joins(
        'LEFT OUTER JOIN units start_units ' \
        '  ON resources.start_unit_id = start_units.id ' \
        'LEFT OUTER JOIN units end_units ' \
        '  ON resources.end_unit_id = end_units.id'
      )
      .order(
        Arel.sql(
          'COALESCE(start_units.rank, 99), COALESCE(end_units.rank, 00), ' \
          'resource_components.name, title'
        )
      )
      .references(:start_units, :resource_components)
  }
  scope :sorted_by_lesson, -> { order(Arel.sql('lesson_id IS NULL, lesson_id')) }

  # sopes for aggregation
  scope :group_by_file_type, lambda {
    select('resources.*, COUNT(resources.file_type) AS resource_file_type_count')
      .group(:file_type)
  }
  scope :group_by_source, lambda {
    select('resources.*, COUNT(resources.source) AS resource_source_count')
      .group(:source)
  }
  scope :group_by_component, lambda {
    select('resources.*, COUNT(resources.resource_component_id) AS resource_component_count')
      .group(:resource_component_id)
      .includes(:resource_component)
  }
  scope :group_by_unit, lambda {
    select('resources.*, COUNT(resources.start_unit_id) AS resource_unit_count')
      .group('start_unit_id, end_unit_id')
      .where('resources.start_unit_id IS NOT NULL')
      .includes(:unit)
  }
  scope :group_by_lesson, lambda {
    select('resources.*, COUNT(resources.lesson_id) AS resource_lesson_count')
      .where('resources.lesson_id IS NOT NULL')
      .group(:lesson_id)
  }

  class << self
    # scope-chaining methods
    def find_student_resource_for_section(resource_id, section)
      unprotected.visible_by_instructor(section.instructor, section).find(resource_id)
    end

    def find_student_resource(resource_id)
      unprotected.visible_to_students.find(resource_id)
    end

    def by_unit(unit)
      resource_unit = (unit.is_a?(Unit) ? unit : Unit.find(unit))
      program_id = resource_unit.program_id
      program_units = Unit.by_program(program_id).select('id, rank').order(:rank)
      units_before = program_units.select { |program_unit| program_unit.rank < resource_unit.rank }
      where(["start_unit_id = ? OR (start_unit_id in (?) AND end_unit_id not in (?))", resource_unit, units_before, units_before])
    end

    # This is just a bad idea.  We're getting ALL resources just to find what 'page'
    # we're going to send a user to? What happens if we are showing more than 10 resources
    # per page?
    def page_for_resource(resource, current_user, params, section)
      resources = find_all_for_user_and_section(
        resource.program, current_user, params, section
      ).base_scope
      resource_index = resources.index { |resource| resource == resource }
      resource_page_location = resource_index / 10
      page_number = resource_page_location.positive? ? resource_page_location : 1
      page_number
    end

    def find_all_for_user_and_section(program, user, opts, section = nil)
      if user.student?
        StudentResourceFinder.new(program, section, opts)
      else
        InstructorResourceFinder.new(user, program, opts)
      end
    end

    # If the user is an instructor, only show resources they uploaded
    def apply_instructor_uploaded_filter(resources, user)
      return if user.student?
      resources.reject! do |resource|
        resource.uploaded? && resource.owner_id != user.id
      end
    end

    def apply_components_filter(resources, component_id)
      # TODO: refactor so taht the filter works with a
      # scope like the by_file_type filter and
      # tbe by_source filter (jmunoz).
      return resources if component_id.blank?
      components_to_filter = [component_id.to_i]
      resources.reject! do |resource|
        !components_to_filter.include?(resource.resource_component_id.to_i)
      end
    end

    def order_resource_results(resources)
      ordered_resources = order_by_units resources
      ordered_resources
    end

    def assigned_resources_ids(resources, section)
      return [] if section.blank?
      assignemnts = Assignment.activity_assignments(section, resources)
      assigned_resources_ids = assignemnts.map(&:assignable_id).uniq
      assigned_resources_ids
    end

    def resources_made_visible_by_instructor(instructor)
      return [] if instructor.blank?
      resource_setting_ids = InstructorResourceSetting.where(
        user_id: instructor.id,
        student_visibility: 'shown'
      ).map(&:resource_id)
      resource_setting_ids
    end

    def resources_made_hidden_by_instructor(instructor)
      return [] if instructor.blank?
      resource_setting_ids = InstructorResourceSetting.where(
        user_id: instructor.id,
        student_visibility: 'hidden'
      ).map(&:resource_id)
      resource_setting_ids
    end

    def human_attribute_name(attribute_key_name, options = {})
      case attribute_key_name.to_sym
      when :file_name then 'File'
      else super
      end
    end
  end

  def dispose_file(old_file_path)
    s3_bucket.delete_file(old_file_path)
  end

  def points_possible
    0
  end

  def gradable?
    false
  end

  def assessment?
    false
  end

  def location_name
    unit = Unit.find_by_id(start_unit_id)
    return '' if unit.blank?
    unit.display_name
  end

  def unit_options_setting
    if start_unit.blank? || start_unit.use_type == 'ResourceUnit'
      'no_unit'
    elsif end_unit
      'unit_range'
    else
      'single_unit'
    end
  end

  def location_name_for_unit(unit_id)
    unit = Unit.find_by_id(unit_id)
    return '' if unit.blank?
    unit.resources_form_display_name
  end

  def location_name_start_end_unit(end_unit_id)
    start_unit_name = location_name
    end_unit_name = Unit.find_by_id(end_unit_id)
    if end_unit_name.blank?
      ''
    else
      "#{start_unit_name} - #{end_unit_name.display_name}"
    end
  end

  def file_path
    real_file_path
  end

  def owner?(user_id)
    owner_id == user_id
  end

  def is_student_viewable?(current_user)
    student_resource_viewable?(self, instructor_resource_setting(current_user), current_user)
  end

  def instructor_resource_setting(current_user)
    InstructorResourceSetting.where(
      user_id: current_user.id,
      resource_id: id,
      student_visibility: 'shown'
    ).first
  end

  def thumbnail_public_path
    random_index = rand(2) + 1
    filename = "#{file_type.downcase}_0#{random_index}.png"
    File.join('generic_resource_thumbnails', filename)
  end

  def component_name
    return '' if resource_component_id.nil?
    resource_component.name
  end

  def resource_component_names
    return '' if resource_component_id.blank?
    resource_component = ResourceComponent.find(resource_component_id)
    names = resource_component.name unless resource_component.blank?
    names = "#{resource_component.name} / #{subcomponent_name}" unless subcomponent_name.blank?
    names
  end

  def subcomponents
    @component = ResourceComponent.find_by_id(@parent_id)
  end

  def has_subcomponents?
    !subcomponents.blank?
  end

  def unit_range_contains?(unit_id, units = [])
    return false if unit_id.blank?
    units = Program.all.flat_map(&:units_and_resource_units).sort_by(&:rank) if units.empty?
    return true if start_unit_id.present? && start_unit_id == unit_id
    return true if start_unit_id == unit_id
    return true if end_unit_id == unit_id
    start_unit = units.detect { |unit| unit.id == start_unit_id }
    start_unit_rank = start_unit.rank unless start_unit.blank?
    end_unit = units.detect { |unit| unit.id == end_unit_id }
    end_unit_rank = end_unit.rank unless end_unit.blank?
    especified_unit = units.detect { |unit| unit.id == unit_id }
    especified_unit_rank = especified_unit.rank unless especified_unit.blank?
    (especified_unit_rank.to_i > start_unit_rank.to_i) &&
      (especified_unit_rank.to_i < end_unit_rank.to_i)
  end

  def start_unit
    return @start_unit if defined? @start_unit
    @start_unit = (start_unit_id.blank? ? nil : Unit.find_by_id(start_unit_id))
    @start_unit
  end

  def end_unit
    return @end_unit if defined? @end_unit
    @end_unit = (end_unit_id.blank? ? nil : Unit.find_by_id(end_unit_id))
    @end_unit
  end

  def toc_location; end

  def editable_by?(current_user)
    if uploaded?
      owner?(current_user.id)
    else
      current_user.is_resource_editor?
    end
  end

  private

  def real_file_path
    if uploaded?
      File.join('resources', current_deployed_env_name,
                program_id.to_s, 'uploaded', owner_id.to_s, id.to_s, file_name)
    else
      File.join('resources', current_deployed_env_name,
                program_id.to_s, id.to_s, file_name)
    end
  end

  def current_deployed_env_name
    M3::Application.config.current_deployed_env_name
  end

  def validate_units
    return unless start_unit || end_unit
    valid_unit_label = (unit_label || 'unit').downcase
    if (start_unit && end_unit) && (end_unit.rank < start_unit.rank)
      errors.add("last_#{valid_unit_label}".to_sym, "must be after First #{valid_unit_label}.")
    end
  end
end
