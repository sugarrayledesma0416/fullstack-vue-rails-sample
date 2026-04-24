class AssignmentDay
  attr_accessor :due_date, :lesson_plan_groups, :total_minutes_for_activities
  attr_accessor :total_minutes_for_assessments, :total_activities, :total_assessments

  def initialize(params={})
    @assignments = []
    @lesson_plan_groups = []
    @due_date = params[:due_date]
    @rank = 1
    @total_minutes_for_activities = 0
    @total_minutes_for_assessments = 0
    @total_activities = 0
    @total_assessments = 0
    @populated = false
    @banks = Array.new
  end

  def <<(assignment)
    @assignments << assignment
  end

  def assignments
    @assignments
  end

  def activities
    return @activities if @activities

    @activities = Array.new()
    if lesson_plan_groups.empty?
      @assignments.each do |assignment|
        @activities << assignment.assignable
      end
    else
      @activities = lesson_plan_groups.flatten
    end
    @activities
  end

  def concepts
    banks.collect{|bank|bank.concept}.uniq
  end

  def banks
    populate_banks unless @populated
    @banks
  end

  # Each lesson_plan_group is an array of ActiveRecord Activity Objects
  def assign_from_lesson_plan_groups(section, category_id)
    if category_id.is_a? Category
      category_id = category_id.id
    end
    lesson_plan_groups.each do |group|
      group.each do |activity|
        assignment = Assignment.create!(:section => section, :category_id => category_id,
                                        :assignable => activity, :due_date => due_date, :rank => @rank)
        self << assignment
        @rank += 1
      end
    end
  end

  def activities_and_assessment_count_label
    activities = ''
    assessments_labels = []
    assessment_types = {}
    if total_activities > 0
      activities = "#{total_activities} "
      if total_activities > 1
        activities << 'activity'.pluralize
      else
        activities << 'activity'
      end
    end
    assessments_labels << activities if activities.present?

    assessment_banks = banks.select { |bank| bank.assessment.present? }
    assessment_banks.each do |assessment_bank|
      if assessment_types[assessment_bank.assessment.strand_singular_label]
        assessment_types[assessment_bank.assessment.strand_singular_label] += 1
      else
        assessment_types[assessment_bank.assessment.strand_singular_label] = 1
      end
    end
    assessment_types.each do |assessment_type, count|
      assessment_label = assessment_type
      if count > 1
        assessment_label = assessment_label.pluralize
      end
      assessments_labels << "#{count} #{assessment_label}"
    end

    assessments_labels.join(' - ')
  end

  private

  def populate_banks
    populate_activity_banks
    populate_assessments_banks
    @populated = true
  end

  def populate_activity_banks
    bank = Bank.new
    activities.each do |activity|
      next if activity.assessment?
      if bank.concept && bank.concept != activity.concept
        store_bank(bank)
        bank = Bank.new
      end
      bank.concept ||= activity.concept
      bank.assigned_count += 1
      bank.assigned_minutes += activity.minutes_to_complete ? activity.minutes_to_complete : 10
    end
    store_bank(bank) if bank.concept
  end

  def populate_assessments_banks
    activities.each do |activity|
      next if !activity.assessment?
      bank = Bank.new
      bank.concept = activity.concept
      bank.assessment = activity
      bank.assigned_count += 1
      bank.assigned_minutes += activity.minutes_to_complete ? activity.minutes_to_complete : 10
      store_bank(bank) if bank.concept
    end
  end

  def store_bank(bank)
    bank.assigned_minutes = bank.assigned_minutes.round_up_to(5)
    if bank.concept.assessment?
      self.total_minutes_for_assessments += bank.assigned_minutes
      self.total_assessments += bank.assigned_count
    else
      self.total_minutes_for_activities += bank.assigned_minutes
      self.total_activities += bank.assigned_count
    end
    @banks << bank
  end
end
