class Category < ApplicationRecord
  include Etl

  NAME_LENGTH_MAX = 15

  # inverse_of for course is needed because course model uses
  # accepts_nested_attributes
  belongs_to :course,
             -> { including_templates },
             inverse_of: :categories

  validates_presence_of :name

  validates_inclusion_of :drop_low_scores, :in => [0, 1, 2, 3, 4, 5], :allow_nil => false

  validates_length_of :name, :maximum => NAME_LENGTH_MAX, :message => "should not be more than #{NAME_LENGTH_MAX} letters"

  validate :weighting_percent_is_an_integer, :category_is_unique_on_course, :penalty_percent_is_an_integer
  validates_numericality_of :weighting_percent, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 100, :message => 'must be a number between 1 and 100'
  validates_numericality_of :penalty_percent, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 100, :message => 'must be a number between 0 and 100'

  validates_numericality_of :max_attempts, :allow_nil => true, :only_integer => true
  validates_inclusion_of :max_attempts, :in => [-1, 1, 2, 3, 4, 5, 6, 7, 8, 9], :allow_nil => true,
                                        :allow_blank => true,
                                        :message => "must be a whole number between 1 and 9 (or -1 for Unlimited attempts)"

  # we never want to return assignments for archived sections
  has_many :assignments, (lambda do
    includes(:section).where(sections: { is_archived: false })
  end)

  has_many :scoring_rulesets
  accepts_nested_attributes_for :scoring_rulesets, :allow_destroy => true

  after_validation :set_default_weighting_percent, :set_penalty_percent, :on => :create
  before_create :set_rank_from_siblings

  before_destroy :verify_destroyable
  after_commit :update_gradebook

  default_scope { where(is_archived: false) }
  scope :by_course, ->(course) { where(course_id: course) }

  # Retrieves categories for course and adds assessment count field to them.
  # An assignment's assessment-ness is determined by a boolean value on
  # an assignment's associated activity's concept.
  scope :with_assessment_count, (lambda do |course|
      select('categories.*, sum(concepts.assessment) AS assessment_count').
      joins('INNER JOIN assignments ON assignments.category_id = categories.id').
      joins('INNER JOIN activities ON activities.id = assignments.assignable_id AND assignments.assignable_type = "Activity"').
      joins('INNER JOIN concepts ON concepts.id = activities.concept_id').
      where(:course_id => course).
      group('categories.id')
    end)

  attr_accessor :index, :has_assignments

  def self.max_attempt_options_for_select
    [
      ['1', 1], ['2 (default)', 2], ['3', 3], ['4', 4], ['5', 5], ['6', 6], ['7', 7],
      ['8', 8], ['9', 9], ['Unlimited', -1]
    ]
  end

  def destroyable?
    return true if assignments.empty?

    errors.add(:base, "Category with assignments cannot be deleted.")
    false
  end

  def set_penalty_percent
    if late_work_penalty == 'none'
      self.penalty_percent = 0
    end
    true
  end
  private :set_penalty_percent

  # If there are assignments, throw(:abort) will interrupt the callback
  # chain and prevent the destroy.
  private def verify_destroyable
    throw(:abort) unless destroyable?
  end

  def name=(new_name)
    write_attribute(:name, new_name.strip) if new_name
  end

  # The following two methods are needed because the edit category view
  # uses a checkbox labeled as enabling enhanced feedback
  def enhanced_feedback_enabled
    !enhanced_feedback_disabled
  end

  def enhanced_feedback_enabled=(value)
    self.enhanced_feedback_disabled = value.eql?('0')
  end

  def weighting_percent_is_an_integer
    raw_weight = send('weighting_percent_before_type_cast') || weighting_percent
    if raw_weight.to_f != raw_weight.to_i.to_f
      errors.add(:weighting_percent, "is not a whole number")
    end
  end

  def penalty_percent_is_an_integer
    raw_weight = send("penalty_percent_before_type_cast") || penalty_percent
    if raw_weight.to_f != raw_weight.to_i.to_f
      errors.add(:penalty_percent, "is not a whole number")
    end
  end

  def category_is_unique_on_course
    return if course.nil?

    has_dupe_name = course.categories.any? do |sibling|
      sibling != self && sibling.name.strip.downcase == name.strip.downcase
    end

    return unless has_dupe_name

    errors.add(
      :name,
      "cannot be '#{name}' because this course already has a category with " \
      'that name. Please choose a different name.'
    )
  end

  def current_scoring_ruleset
    @current_scoring_ruleset ||= ScoringRuleset.find_by_id(current_scoring_ruleset_id)
    @current_scoring_ruleset ||= ScoringRuleset.default.dup
    @current_scoring_ruleset
  end

  def late_penalty_percent(late_by)
    if accept_late_work?
      case late_work_penalty
      when 'none' then 0
      when 'percent_per_day'
        penalty = late_by * penalty_percent
        (penalty > 100 ? 100 : penalty)
      when 'flat_percent'
        penalty_percent
      end
    else
      100
    end
  end

  def self.human_attribute_name(attribute_key_name, options = {})
    case attribute_key_name.to_sym
    when :weighting_percent then 'Weight'
    when :max_attempts then 'Maximum Attempts Allowed'
    else super
    end
  end

  def max_attempts
    read_attribute(:max_attempts) || 2
  end

  def unlimited_attempts?
    max_attempts == -1
  end

  def has_assignments?
    assignments.size > 0
  end

  def has_assessment_assignments?
    assignments.any?(&:assessment?)
  end

  def set_rank_from_siblings
    return unless rank.zero? && course

    self.rank = (course_max_category_rank + 1)
  end

  private def course_max_category_rank
    max_category = Category.where(course_id: course_id).order(:rank).last
    max_category&.rank.to_i || 0
  end

  def invalid_for_update?
    invalid? || (marked_for_destruction? && !destroyable?)
  end

  def lessons
    return @lessons if @lessons
    units = []
    course.sections.each do |section|
      units.concat(section.course.units_covered)
    end
    cat_lessons = units.flat_map(&:lesssons)
    @lessons = cat_lessons.uniq.sort_by(&:rank)
  end

  def self.sorted_indices(categories, index_to_move = nil)
    return [] if categories.blank?
    unsorted_categories = categories.dup
    unsorted_categories.each_with_index{|category, index| category.index ||= index.to_s }

    if index_to_move
      target_category = unsorted_categories.find{|category| category.index == index_to_move.to_s}
      unsorted_categories.to_a.reject!{|category| category == target_category}
    end

    sorted_category_indices = []

    ranked_categories = unsorted_categories.sort_by{|category| category.rank}
    ranked_categories.each do |category|
      next if sorted_category_indices.include? category.index

      if index_to_move
        if (sorted_category_indices.size >= (target_category.rank - 1)) && !sorted_category_indices.include?(index_to_move.to_s)
          sorted_category_indices << target_category.index
        end
      end

      sorted_category_indices << category.index
    end

    if index_to_move && !sorted_category_indices.include?(index_to_move.to_s)
      sorted_category_indices << target_category.index
    end

    sorted_category_indices
  end

  def to_hash
    {'name' => name,
     'weighting_percent' => weighting_percent.to_s,
     'rank' => rank.to_s,
     'group_name' => group_name.to_s,
     'id' => id.to_s}
  end

  def set_default_weighting_percent
    self.weighting_percent = 100 unless weighting_percent
  end
  private :set_default_weighting_percent

  # overrides is_deleted in the Etl module
  def is_deleted?
    is_archived || super
  end
end
