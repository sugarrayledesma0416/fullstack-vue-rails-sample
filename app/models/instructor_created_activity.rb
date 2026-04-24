class InstructorCreatedActivity < Activity
  include ActivityIcons

  ASSIGNMENT_GROUPS = %w[Explore Learn Practice Communicate Self-check Assessment].freeze
  JSON_TYPES = %w[
    drop_down
    external_link
    fill_in_the_blanks
    multiple_answer
    multiple_choice
    multiple_choice_same
    open_ended
    recording_v2
    solo_video_recording
    upload_file_activity
  ].freeze

  belongs_to :instructor
  has_many :instructor_activity_revisions, foreign_key: :activity_id
  has_many :courses, through: :course_library_activities

  has_many :sections, -> { distinct }, through: :assignments
  has_many :assignment_courses, -> { distinct }, through: :sections, source: :course

  has_many(
    :custom_rubrics,
    foreign_key: :activity_id,
    inverse_of: :instructor_created_activity
  )

  attr_accessor :language_code, :generated_content, :process_as_assessment
  attr_writer :direction_line, :question_prompt, :video_url, :video_platform

  alias_attribute :toc_entry_id, :toc_location

  validates :title, presence: true
  validate :valid_video_id, if: proc { |instance| instance.activity_type == 'external_video' }
  validate :validate_link, if: proc { |instance| instance.activity_type == 'external_link' }
  validates_with BlankWolsValidator

  # concept_id has to be set before validation or required belongs_to
  # validation will fail.
  before_validation :set_concept, unless: :process_as_assessment
  before_save :process_callbacks_for_activity,
              :set_default_component_name,
              :set_license_group_id,
              :set_default_rank

  after_save :increment_version
  after_save :store_xml, unless: :has_json_content?
  after_save :set_denormalized_values
  after_commit :update_rubric_revision_id
  after_commit :update_rubric_draft_status, on: :update

  default_scope { where('activities.instructor_revision_id IS NOT NULL') }
  scope :instructor, ->(instructor) { where(instructor_id: instructor.id) }
  scope :with_mapped_concept_in_program, lambda { |program|
    joins(%(inner join program_to_program_mappings ptpm
            on activities.concept_id = ptpm.src_strand_id))
      .joins(concept: [lesson: [:unit]])
      .where('units.program_id = ?', program.id)
      .where('ptpm.dest_strand_id is not null')
  }
  after_commit :update_gradebook_assignment_locations, on: :update

  DEFAULT_TOC_RANK = 0

  def initialize(opts = {})
    super
    self.cdn = (Rails.env.live? && new_record?)
  end

  def all_courses
    @all_courses ||= (courses + assignment_courses).uniq
  end

  def custom_rubric
    custom_rubrics.find_by(activity_revision_id: instructor_revision_id)
  end

  def copy_to_instructor(instructor_id)
    InstructorCreatedActivityForCopy.copy(instructor_id, self)
  end

  def direction_line
    return @direction_line if new_record? || @direction_line

    # Removes newline characters from direction line HTML.
    # Base class (activity.rb) calls Nokogiri's `to_html`, which introduces newlines,
    # causing issues with list items in Froala editor in IGC builder.
    # Adjusting here instead of the base class to minimize regression risk.
    @direction_line || super&.gsub(/\n/, '')
  end

  def instructor_full_name
    instructor.full_name
  end

  def instructor_avatar
    instructor.avatar_thumb_url
  end

  def instructor_initials
    instructor.full_name_initials
  end

  def question_prompt
    if new_record?
      @question_prompt
    else
      @question_prompt || xml_question_prompt
    end
  end

  def has_json_content?
    if new_record?
      stores_as_json?
    else
      content_json.present?
    end
  end
  private :has_json_content?

  def process_callbacks_for_activity
    unless process_as_assessment
      generate_xml unless has_json_content? || has_rubric?
    end
    set_icon unless has_rubric?
  end
  private :process_callbacks_for_activity

  def xml_question_prompt
    defined?(questions.first.prompt) &&
      questions.first.prompt &&
      questions.first.prompt.children.to_html
  end
  private :xml_question_prompt

  # This is done for rendering the right partial
  # Here the legacy recording_v2(audio_composition) is stored as xml, and modern recording_v2
  # is stored as JSON. So adding a check of content_json.nil? will stop converting the
  # actual recording_v2 to audio_composition.
  def activity_type
    if self[:activity_type].eql?('recording_v2') && content_json.nil?
      'audio_composition'
    else
      self[:activity_type]
    end
  end

  def video_url
    if new_record?
      @video_url
    else
      @video_url || xml_video_url
    end
  end

  def xml_video_url
    content_object.respond_to?(:video_url) &&
      content_object.video_url
  end
  private :xml_video_url

  def video_platform
    # return "" for new
    # return @video_platform for create/update
    # return value from saved xml for edit
    if new_record?
      @video_platform || ''
    else
      @video_platform || xml_video_platform
    end
  end

  private def xml_video_platform
    content_object.respond_to?(:video_platform) &&
    content_object.video_platform
  end

  def references
    args = { :instructor_id => instructor_id }
    args[:content_object] = content_object unless new_record?
    @references ||= InstructorCreatedActivity::ReferenceCollection.new(args)
  end

  def references=(references_params)
    @references = InstructorCreatedActivity::ReferenceCollection.new({form_params: references_params, instructor_id: instructor_id})
  end

  def parsed_references
    references.parse
  end

  def in_library?(course)
    courses.include?(course)
  end

  def generate_xml
    return if generated_content.present?

    # we're setting activity_type from within the new activity view. So, at this point we want
    # activity type to contain the name of the activity template to be used inside Mae::InstructorCreatedContent,
    # then, after_save callback will take care of update activity_type with the correct value.
    # note: activity_type inside xml should be a correct mae activity type.
    self.generated_content = MaestroActivityEngine::InstructorCreatedContent.new(activity_type).generate_xml(self)
  end
  private :generate_xml

  def set_icon
    self.icon = icon_for_activity_type
  end
  private :set_icon

  private def update_gradebook_assignment_locations
    # Only update if either the lesson or the strand have changed.
    return if (saved_changes.keys & %w[lesson_id toc_location]).empty?

    assignments.joins(:section).merge(Section.open).each(&:update_gradebook)
  end

  def increment_version
    new_revision = instructor_activity_revisions.create! do |revision|
      revision.content_json = content_json
    end

    # update head revision without triggering callbacks
    update_column(:instructor_revision_id, new_revision.id)
    assign_new_content_instance
  end
  private :increment_version

  def store_xml
    activity_content.store_content(generated_content)
  end
  private :store_xml

  private def set_default_rank
    self.toc_location_rank ||= DEFAULT_TOC_RANK
    self.concept_rank ||= DEFAULT_TOC_RANK
  end

  private def set_default_component_name
    self.component_name ||= 'Instructor-created Activities'
  end

  def set_license_group_id
    license_group = license_groups.detect { |lg| lg.name =~ /#{desired_license_group_name}/ }
    self.license_group_id = license_group && license_group.id
  end
  private :set_license_group_id

  def license_groups
    @license_groups ||= Maestro::LicenseGroup.all
  end
  private :license_groups

  def desired_license_group_name
    if program.vista_online_learning?
      'VOL'
    else
      '01-Supersite'
    end
  end
  private :desired_license_group_name

  def set_concept
    self.concept_id = lesson.strand_for_toc_location(toc_entry_id).location
  end
  private :set_concept

  # We need to send empty references to instructor_created_content
  # in case user deletes all references.
  def update(params)
    params[:references] ||= []
    super(params)
  end

  def video_id
    self.video_url = MaestroActivityEngine::ActivityContent::ExternalVideoContent
                     .parse_video_id(video_url, video_platform)
  end
  private :video_id

  def validate_link
    url_validator = ExternalUrlValidator.new(attributes: [:external_url_link])
    url_validator.validate_each(
      self,
      :external_url_link,
      content_object.external_link_url
    )
  end
  private :validate_link

  def valid_video_id
    errors.add(:video_url, 'does not refer to a valid video') if video_id.nil?
  end
  private :valid_video_id

  private def non_assessment_json_type?
    JSON_TYPES.include?(self[:activity_type])
  end

  private def stores_as_json?
    process_as_assessment || non_assessment_json_type?
  end

  private def update_rubric_revision_id
    target = custom_rubrics.last
    return unless target

    if target.activity_revision_id.nil?
      target.update!(activity_revision_id: instructor_revision_id)
    else
      custom_rubrics << target.dup.tap do |memo|
        memo.activity_revision_id = instructor_revision_id
      end
    end
  end

  private def update_rubric_draft_status
    # Only execute if changing draft from true to false
    return unless draft_previously_changed? && draft == false

    target = custom_rubrics.last
    return unless target

    CustomRubric.transaction do
      target.update!(draft: false)

      course_id = target.course_id
      source_activity = target.source_activity

      assignment_checker = ActivityAssignment.new(
        source_activity, instructor, _program = nil, { course_id: }
      )
      next if assignment_checker.assignments.present?

      CourseLibraryActivity.hide_activity(source_activity.id, course_id)
    end
  end

  class InstructorCreatedActivity::ReferenceCollection
    attr_accessor :list, :instructor_id

    def initialize(args = {})
      self.list = []
      self.instructor_id = args[:instructor_id]

      if args[:content_object] && args[:content_object].respond_to?(:references_params)
        populate_list(args[:content_object].references_params)
      end
      populate_list(args[:form_params].values) if args[:form_params].present?
    end

    def to_json
      list.map(&:params).to_json
    end

    def populate_list(references)
      if references.present?
        self.list = references.map do |reference|
          InstructorCreatedActivity::Reference.new(reference.merge!('instructor_id' => instructor_id))
        end
      end
    end
    private :populate_list

    def parse
      list.keep_if { |reference| reference.valid? }
      list.inject([]) do |memo, reference|
        memo << reference.send("parse_#{reference.type}".to_sym)
      end
    end
  end

  class InstructorCreatedActivity::Reference

    attr_accessor :attributes
    VALID_TYPES = ['image', 'text', 'wordbank', 'audio', 'video_recording']

    def initialize(attributes)
      self.attributes = attributes.stringify_keys
      attributes.each do |key, value|
        self.class.send(:define_method, key.to_sym) do
          instance_variable_get("@#{key}")
        end

        instance_variable_set("@#{key}", value)
      end
    end

    def file_was_uploaded?
      type.eql?('image') && temp_file_path.present? && original_filename.present?
    end
    private :file_was_uploaded?

    def parse_image
      if respond_to?(:instructor_media_item_id) && instructor_media_item_id
        {
          'type' => type,
          'image' => { 'id' => instructor_media_item_id || id }
        }
      else
        {
          'type' => type,
          'image' => { 'id' => media_item_id || id }
        }
      end
    end

    # If the recorded audio is implemented using old implementation,
    # permitted params will recieve recording_path and if it is recorded by
    # new implementation i.e. using media item then the permitted params
    # will receive media_item_id.
    def parse_audio
      if respond_to?(:recording_path) && recording_path
        {
          'type' => type,
          'recording' => { 'id' => recording_id || id }
        }
      elsif respond_to?(:instructor_media_item_id) && instructor_media_item_id
        {
          'type' => type,
          'audio' => { 'id' => instructor_media_item_id }
        }
      else
        {
          'type' => type,
          'audio' => { 'id' => id }
        }
      end
    end

    def parse_text
      text_params
    end

    def parse_video_recording
      {
        'type' => type,
        'video_recording' => { 'id' => video_recording_id || id }
      }
    end

    def parse_wordbank
      wordbank_params
    end

    def video_recording_id
      if id.blank?
        VideoRecording.create(recording_path: video_recording_path).id.to_s
      else
        video_recording = VideoRecording.find_by(id: id)
        video_recording&.update(recording_path: video_recording_path)
        id.to_s
      end
    end

    def media_item_id
      media_item && media_item.id && media_item.id.to_s
    end
    private :media_item_id

    def media_item
      @media_item ||= (file_was_uploaded? && InstructorMediaItem.create_from_temp_file(attributes))
    end
    private :media_item

    def recording_id
      Recording.create(recording_path: recording_path).id.to_s if id.blank?
    end

    def text_params
      attributes.slice('type', 'body', 'header')
    end
    private :text_params

    def image_public_filename
      InstructorMediaItem.where(id: attributes['id']).first.try(:public_filename)
    end
    private :image_public_filename

    def audio_params
      if attributes['audio_type'] == 'audio'
        attributes['url'] = InstructorMediaItem.find_by(id: id).try(:public_filename)
        attributes.slice('type', 'id', 'url')
      else
        attributes['recording_path'] = Recording.where(id: id).first.try(:recording_path)
        attributes.slice('type', 'id', 'recording_path')
      end
    end
    private :audio_params

    def image_params
      attributes['image_filename'] = image_public_filename
      attributes.slice('type', 'id', 'image_filename')
    end
    private :image_params

    def formatted_wordbank_body
      if attributes['body'].present?
        attributes['body'] = attributes['body'].tr("\n", ',')
      end
    end
    private :formatted_wordbank_body

    def video_recording_params
      attributes['video_recording_path'] = VideoRecording.where(id: id).first.try(:recording_path)
      attributes.slice('type', 'id', 'video_recording_path')
    end
    private :video_recording_params

    def wordbank_params
      formatted_wordbank_body
      attributes.slice('type', 'body')
    end
    private :wordbank_params

    def params
      send("#{type}_params") if valid?
    end

    def valid?
      VALID_TYPES.include?(type)
    end
  end
end
