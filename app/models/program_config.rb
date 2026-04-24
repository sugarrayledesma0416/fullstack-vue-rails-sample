class ProgramConfig < ApplicationRecord
  include Dangerfield::Publisher

  COURSE_SETUP_DESCRIPTIONS = %w[express_course advanced_course learning_tracks].freeze
  LEARNING_TRACKS_DESCRIPTIONS = %w[header general options_overall options].freeze
  LEARNING_TRACK_OPTIONS = %w[label explanation].freeze

  # JSON DATASTORE STRUCTURE
  # {
  #   settings: [
  #     {
  #       label: "Label 1",
  #       link: "some/link/1",
  #       type: "type_1"
  #     },
  #     {
  #       label: "Label 2",
  #       link: "some/link/2",
  #       type: "type_2"
  #     }
  #   ],
  #   ai_settings: {
  #     grading_suggestions: false,
  #     program_level: "introductory"
  #   },
  #   vtext: {
  #     type: "vText or eCompanion"
  #     url: "vtext/url/book.html"
  #   },
  #   vtext_label: 'some vtext label',
  #   teacher_vtext: {
  #     url: "teacher_vtext/url/book.html"
  #   },
  #   teacher_vtext_label: 'some teacher vtext label',
  #   vocab_tools: "Override Vocab tools title for Content Menu",
  #   speech_rec: true,
  #   standards_settings: {
  #     min_grade: "PK",
  #     max_grade: "1",
  #     supported_standard_set_ids: [123, 345],
  #   },
  #   study_center: false,
  #   course_setup_descriptions: {
  #     express_course: "<b>Express</b> course description",
  #     advanced_course: "<b>Advanced</b> course description",
  #     learning_tracks: {
  #                          header: "Learning tracks",
  #                          general: "General learning track description.",
  #                          options_overall: "Learning track opitons description.",
  #                          options: [
  #                            {
  #                              label: "Essentials",
  #                              explanation: "What option 1 covers"
  #                            },
  #                            {
  #                              label: "Complete",
  #                              explanation: "What option 2 covers"
  #                            }
  #                          ]
  #                        }
  #   }
  # }

  store(
    :datastore_json,
    accessors: %i[
      ai_settings
      allow_assessments_randomization
      audio_transcripts
      content_menu_additional_entries
      course_setup_descriptions
      ebook
      hide_activities
      hide_assessment
      hide_my_content
      hide_translation
      practice_test_analytics_enabled
      pronto
      question_banks_enabled
      settings
      share_to_portfolio
      show_skills_and_refinement_filters
      enable_concurrent_enrollment
      speech_rec
      pmr_standard_reports_allowed
      standards_settings
      study_center
      teacher_vtext
      teacher_vtext_label
      vocab_definition
      vocab_tools
      vocab_words
      vtext
      vtext_label
    ],
    coder: JSON
  )

  belongs_to :program
  belongs_to :creator, class_name: 'User', foreign_key: :creator_id

  after_save :log_datastore

  scope :program_version_history, ->(program) { where(program_id: program).order('created_at DESC') }

  validates :program_id, presence: true
  validates :creator_id, presence: true
  validate :values_have_changed
  validate :course_setup_description_presence, if: :vista_online_learning?
  validate :validate_supported_standard_sets
  validate :validate_min_max_grade_settings

  delegate :vista_online_learning?, to: :program, allow_nil: true

  # Up to March 2023, boolean attributes were considered false if the attribute
  # was not defined in the datastore hash, and true otherwise.
  # For all these boolean attributes, we use double negation when setting a
  # value and we use double negation when getting a value. By doing that, we
  # still have the same behavior as before, and we now explicitly save true or
  # false in the hash. This makes the code easier to understand and records
  # easier to analyze from the console.
  def allow_assessments_randomization=(value)
    super(!!value)
  end

  def allow_assessments_randomization
    !!super
  end

  def allow_assessments_randomization?
    allow_assessments_randomization
  end

  def audio_transcripts=(value)
    super(!!value)
  end

  def audio_transcripts
    !!super
  end

  def audio_transcripts?
    audio_transcripts
  end

  def hide_activities=(value)
    super(!!value)
  end

  def hide_activities
    !!super
  end

  def hide_activities?
    hide_activities
  end

  def hide_assessment=(value)
    super(!!value)
  end

  def hide_assessment
    !!super
  end

  def hide_assessment?
    hide_assessment
  end

  def hide_my_content=(value)
    super(!!value)
  end

  def hide_my_content
    !!super
  end

  def hide_my_content?
    hide_my_content
  end

  def hide_translation=(value)
    super(!!value)
  end

  def hide_translation
    !!super
  end

  def hide_translation?
    hide_translation
  end

  def practice_test_analytics_enabled=(value)
    super(!!value)
  end

  def practice_test_analytics_enabled
    !!super
  end

  def practice_test_analytics_enabled?
    practice_test_analytics_enabled
  end

  def pronto=(value)
    super(!!value)
  end

  def pronto
    !!super
  end

  def pronto?
    pronto
  end

  def question_banks_enabled=(value)
    super(!!value)
  end

  def question_banks_enabled
    !!super
  end

  def question_banks_enabled?
    question_banks_enabled
  end

  def pmr_standard_reports_allowed=(value)
    super(!!value)
  end

  def pmr_standard_reports_allowed
    !!super
  end

  def pmr_standard_reports_allowed?
    pmr_standard_reports_allowed
  end

  def share_to_portfolio=(value)
    super(!!value)
  end

  def share_to_portfolio
    !!super
  end

  def share_to_portfolio?
    share_to_portfolio
  end

  def show_skills_and_refinement_filters=(value)
    super(!!value)
  end

  def show_skills_and_refinement_filters
    !!super
  end

  def show_skills_and_refinement_filters?
    show_skills_and_refinement_filters
  end

  def enable_concurrent_enrollment=(value)
    super(!!value)
  end

  def enable_concurrent_enrollment
    !!super
  end

  def enable_concurrent_enrollment?
    enable_concurrent_enrollment
  end

  def speech_rec=(value)
    super(!!value)
  end

  def speech_rec
    !!super
  end

  def speech_rec?
    speech_rec
  end

  def study_center=(value)
    super(!!value)
  end

  def study_center
    !!super
  end

  def study_center?
    study_center
  end

  def vocab_definition=(value)
    super(!!value)
  end

  def vocab_definition
    !!super
  end

  def vocab_definition?
    vocab_definition
  end

  # vocab_tools is a string. This method returns true if a string is set, even
  # if it's a blank one.
  def vocab_tools?
    datastore.key?(:vocab_tools)
  end

  def vocab_words=(value)
    super(!!value)
  end

  def vocab_words
    !!super
  end

  def vocab_words?
    vocab_words
  end

  def vtext
    super ? OpenStruct.new(super) : nil
  end

  # The vtext attribute is a hash containing a type and a url
  # This method return true if the hash is present, even if it's empty.
  def vtext?
    datastore.key?(:vtext)
  end

  # teacher_vtext is a hash containing only a url key.
  def teacher_vtext
    super ? OpenStruct.new(super) : nil
  end

  # returns true if teacher_vtext exists and contain a non-blank url.
  def teacher_vtext?
    teacher_vtext&.url.present?
  end

  def content_menu_additional_entries
    (super || []).map { |hash| OpenStruct.new(hash) }
  end

  def course_setup_descriptions
    DescriptionBuilder.new(datastore).build
  end

  def self.currently_active(program)
    ProgramConfig.program_version_history(program).first
  end

  # For compatibility reasons
  def datastore
    return datastore_json
  end

  def settings
    (super || []).map { |hash| OpenStruct.new(hash) }
  end

  def settings_as_json
    (datastore[:settings] || []).to_json
  end

  def setup_descriptions
    datastore[:course_setup_descriptions]
  end

  def ai_settings=(value)
    super({
      grading_suggestions: !!value[:grading_suggestions],
      program_level: value[:program_level]
    })
  end

  def ai_settings
    super || {}
  end

  def ai_grading_feature_enabled?
    !!ai_settings[:grading_suggestions]
  end

  def ai_program_level
    ai_settings[:program_level]
  end

  def standards_settings=(value)
    supported_standard_set_ids = normalize_supported_standard_set_ids(
      value[:supported_standard_set_ids]
    )
    min_grade = value[:min_grade]
    max_grade = value[:max_grade]

    super({
      supported_standard_set_ids:,
      min_grade:,
      max_grade:
    })
  end

  def standards_settings
    super || {}
  end

  def grouped_supported_standard_set_ids
    if supported_standard_set_ids.present?
      sets = StandardSet.select(:id, :display_name)
                        .where(id: supported_standard_set_ids)
                        .group_by(&:display_name)
                        .map do |display_name, id|
        {
          name: display_name,
          ids: id.map(&:id).join(',')
        }
      end
      sets.pluck(:ids)
    else
      []
    end
  end

  def supported_standard_set_ids
    standards_settings[:supported_standard_set_ids] || []
  end

  def has_supported_standard_sets_selected?
    supported_standard_set_ids.present?
  end

  def supported_standard_sets
    if supported_standard_set_ids.present?
      StandardSet.where(id: supported_standard_set_ids)
    else
      []
    end
  end

  def has_min_grade?
    standards_settings[:min_grade].present?
  end

  def has_max_grade?
    standards_settings[:max_grade].present?
  end

  # to add Immutability
  # http://jgtr.github.io/blog/2013/06/16/immutability-in-ruby-applications/
  # https://github.com/prognostikos/activerecord-immutable
  def readonly?
    persisted?
  end

  def touch
    raise_error
  end

  def delete
    raise_error
  end

  private def raise_error
    raise ActiveRecord::ReadOnlyRecord
  end

  private def course_setup_description_presence
    validator = DescriptionValidator.new(course_setup_descriptions).validate
    validator.description_errors.each { |error| errors.add(:base, error) }
  end

  private def values_have_changed
    active_setting = ProgramConfig.currently_active(program_id)
    # We do not allow progra_config editing, only creating a new one each time.
    # In this validation we check that the new one is not the same as the previous one,
    # to prevent creating configs where not changes were made.
    if active_setting && active_setting.id != self.id &&
      datastore == active_setting.datastore
      errors.add(:no_changes, ': Program settings remain the same.')
    end
  end

  private def normalize_supported_standard_set_ids(id_or_ids)
    return unless id_or_ids

    set_ids = Array(id_or_ids).flat_map { |ids| ids.split(',') }.uniq
    validate_supported_standard_set_ids(set_ids)
    set_ids.map(&:to_i)
  end

  private def validate_min_max_grade_settings
    if has_supported_standard_sets_selected?
      errors.add(:min_grade, 'is required when a standard set is selected') unless has_min_grade?
      errors.add(:max_grade, 'is required when a standard set is selected') unless has_max_grade?
    else
      errors.add(:min_grade, 'must be blank when no standard set is selected') if has_min_grade?
      errors.add(:max_grade, 'must be blank when no standard set is selected') if has_max_grade?
    end
  end

  private def validate_supported_standard_sets
    validate_supported_standard_set_ids(supported_standard_set_ids)
  end

  private def raise_on_type_mismatch!(record, expected_class)
    unless record.is_a?(expected_class)
      message = "#{expected_class.name} expected, got #{record.inspect} which is an " \
                "instance of #{record.class}"
      raise ActiveRecord::AssociationTypeMismatch, message
    end
  end

  # This method validates an array of ids just like active records does when we
  # use the has_many relation.
  private def validate_supported_standard_set_ids(ids)
    return unless ids

    result = StandardSet.where(id: ids).pluck(:id).map(&:to_s)
    if result.count != ids.count
      error = if ids.count == 1
                "Couln't find Standard set with 'id'=[#{ids.first}]"
              else
                not_found_ids = ids - result
                "Couln't find all Standard sets with 'id': (#{ids.join(', ')}) " \
                  "(found #{result.count} results, but was looking for #{ids.count}). " \
                  "Couldn't find Standard sets with ids #{not_found_ids.join(', ')}"
              end
      raise ActiveRecord::RecordNotFound.new(error, StandardSet.name, :id, ids)
    end
  end

  private def log_datastore
    log_data = {
      application: 'm3',
      environment: Rails.env,
      vhl_component: :program_config,
      event_action: 'Program Config',
      id: id,
      program_id: program.id,
      creator_id: creator_id,
      datastore_json: datastore
    }
    Rails.logger.debug("Program Config: #{log_data.inspect}")
    STATS_PROXY.info(log_data)
  end

  class DescriptionBuilder
    ROOT_DESCRIPTIONS_KEY = 'course_setup_descriptions'.freeze

    attr_reader :datastore

    def initialize(datastore)
      @datastore = datastore
    end

    def build
      description_object = parse_value(descriptions(ROOT_DESCRIPTIONS_KEY))
      description_object.learning_tracks = parse_value(descriptions('learning_tracks_descriptions'))
      description_object.learning_tracks.options = parse_value(descriptions('learning_track_options'))
      description_object
    end

    private def parse_value(value)
      case value.class.to_s
      when 'Hash', 'ActiveSupport::HashWithIndifferentAccess'
        OpenStruct.new(value)
      when 'Array'
        value.map { |inner_setting| parse_value(inner_setting) }
      else
        value
      end
    end

    private def descriptions(hash_key)
      unless hash_key == 'learning_track_options'
        return stored_or_default_hash(description_hash(hash_key), description_constant(hash_key))
      end
      learning_track_options.map do |option|
        stored_or_default_hash(option, description_constant(hash_key))
      end
    end

    private def stored_or_default_hash(hash, description_collection)
      hash.present? ? hash : Hash[description_collection.map { |item| [item, ''] }]
    end

    private def learning_track_options
      learning_track_descriptions_hash['options'] || [{},{}]
    end

    private def description_hash(key)
      key == ROOT_DESCRIPTIONS_KEY ? root_hash : learning_track_descriptions_hash
    end

    private def root_hash
      @root_hash ||= datastore[ROOT_DESCRIPTIONS_KEY] || {}
    end

    private def learning_track_descriptions_hash
      @learning_track_descriptions_hash ||= root_hash['learning_tracks'] || {}
    end

    private def description_constant(key)
      "ProgramConfig::#{key.upcase}".constantize
    end
  end

  class DescriptionValidator
    DESCRIPTION_SET_CONSTANTS = {
      course_setup: 'COURSE_SETUP_DESCRIPTIONS',
      learning_tracks: 'LEARNING_TRACKS_DESCRIPTIONS',
      options: 'LEARNING_TRACK_OPTIONS'
    }.freeze

    attr_reader :descriptions

    def initialize(descriptions)
      @descriptions = descriptions
      @description_errors = []
    end

    def validate
      validate_description_set(descriptions, :course_setup)
      self
    end

    def description_errors
      @description_errors.reverse
    end

    private def validate_description_set(description_set, set_name)
      missing_descriptions = description_constant(set_name)
      missing_descriptions.to_a.delete_if do |description|
        recursive_validation(description_set, description)
      end
      add_errors(missing_descriptions, set_name)
    end

    private def add_errors(missing_descriptions, set_name)
      return unless missing_descriptions.any?
      @description_errors << "#{set_name.to_s.humanize} description missing: " \
                             "#{missing_descriptions.map(&:humanize).join(', ')}"
    end

    private def recursive_validation(description_set, description)
      case description
      when 'learning_tracks'
        validate_description_set(description_set.learning_tracks, description.to_sym)
        true
      when 'options'
        description_set.options.each do |option|
          validate_description_set(option, description.to_sym)
        end
        true
      else
        description_set.respond_to?(description) && description_set.method(description).call.present?
      end
    end

    private def description_constant(set_name)
      "ProgramConfig::#{DESCRIPTION_SET_CONSTANTS[set_name]}".constantize.dup
    end
  end
end
