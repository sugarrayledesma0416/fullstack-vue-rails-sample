require 'ostruct'

class EventDay
  attr_accessor :date, :lesson_plan_groups, :total_minutes, :total_activities,
                :category_assignments, :categories, :calendar_settings

  delegate :clickable_category_links?, :to => :calendar_settings

  def initialize(params={})
    @events = []
    @lesson_plan_groups = []
    @date = params[:date]
    @active_month = params[:active_month]
    @calendar_settings = params[:calendar_settings]
    @week = params[:week]
    @from_date = @calendar_settings.start_date
    @to_date = @calendar_settings.end_date
    @rank = 1
    @total_minutes = 0
    @total_activities = 0
    @populated = false
    @banks = Array.new
    @category_assignments = {}
    @assessments_assignments = []
  end

  def <<(event)
    @events << event
    @assessments_assignments << event if event.is_a?(Assignment) && event.assignable.assessment?
  end

  def events
    @events
  end

  def assignments
    @events.select { |event| event.is_a?(Assignment) }.compact
  end

  def is_course_end_day?
    date == @to_date
  end

  def prev_day
    @week.prev_day(self)
  end

  def section_class_days_vary?
    @calendar_settings.type == 'course' && @calendar_settings.section_class_days_vary?
  end

  def update_categories(categories)
    categories.each do |cat|
      @category_assignments[cat.name] = assignments_for_category(cat) unless @category_assignments[cat.name]
    end
    @categories = categories
  end

  def uniform_assignments_for?(category, lesson_label = nil)
    return true if @calendar_settings.section_count == 1

    filtered_assignments = if lesson_label.blank?
                             @category_assignments[category.name]
                           else
                             assignments_by_category_and_lesson(category, lesson_label)
                           end

    section_buckets = {}

    filtered_assignments.each do |assignment|
      if section_buckets[assignment.section_id]
        section_buckets[assignment.section_id] << assignment.assignable_id
      else
        section_buckets[assignment.section_id] = [assignment.assignable_id]
      end
    end

    @calendar_settings.sections.each do |section|
      section_buckets[section.id] = section_buckets[section.id].sort if section_buckets[section.id]
    end

    @calendar_settings.sections.each do |section_left|
      @calendar_settings.sections.each do |section_right|
        next if section_left.id == section_right.id
        return false unless section_buckets[section_left.id] == section_buckets[section_right.id]
      end
    end
    true
  end

  def assignments_for_category(category)
    return @category_assignments[category.name] if @category_assignments[category.name]

    events.select do |event|
      event.is_a?(Assignment) && event.category_id == category.id && !event.assignable.assessment?
    end
  end

  def activities
    return @activities if @activities

    @activities = Array.new()
    if lesson_plan_groups.empty?
      @events.each do |event|
        @activities << event.assignable if event.respond_to?(:assignable)
      end
    else
      @activities = lesson_plan_groups.flatten
    end
    @activities
  end

  def id
    date.strftime('%Y%m%d')
  end

  def valid_day?
    date.month == @active_month
  end

  def today?
    date == Time.zone.now.to_date
  end

  def class_day?
    return false if date < @from_date || date > @to_date
    @calendar_settings.class_days.include?(date.wday.to_s)
  end

  def css_classes
    css_class = 'day  js-day'
    if valid_day?
      css_class << (today? ? ' today  c-day--today  js-day--today' : '')
      css_class << (class_day? ? ' class_day  c-day--class-day  js-day--class-day' : '')
    end
    css_class
  end

  def concepts
    banks.collect{|bank| bank.concept}.uniq
  end

  def banks
    populate_banks unless @populated
    @banks
  end

  def day
    date.day
  end

  def category_links
    # Don't call this on a day with no events.
    # For a month view, calling this unnecessarily is causing us nearly 1s in processing time.
    category_links = []
    lesson_labels.each do |lesson_label|
      categories.each do |category|
        assignments_grouped = assignments_by_category_and_lesson(category, lesson_label)
        count_label = category_count_label(assignments_grouped)
        url_options = @calendar_settings.category_link_params
        url_options[:action] = :index if @calendar_settings.is_instructor? &&
                                         !uniform_assignments_for?(category, lesson_label)
        html_options = @calendar_settings.category_html_options
        unless uniform_assignments_for?(category, lesson_label)
          html_options[:title] = 'Viewing due dates'
          count_label = 'varies'
        end

        next if count_label == 0

        if @calendar_settings.is_instructor?
          url_options[:selected_assignments] = assignments_grouped.map(&:id).join(',')
          url_options[:selected_activities] =
            populate_selected_assignables!(Activity, assignments_grouped)
          html_options[:id] =
            "set_due_date_link_#{category.id}_#{@category_assignments[category.name].first.id}"
        else
          url_options[:assignment_day] = date.strftime('%Y-%m-%d')
          url_options[:category_id] = category.id.to_s
        end
        category_links << OpenStruct.new(
          name: "#{lesson_label}: #{category.name}", count_label:, url_options:, html_options:
        )
      end
    end
    category_links
  end

  private def assignments_by_category_and_lesson(category, lesson_label)
    @category_assignments[category.name]
      .select { |assignment| assignment.assignable_lesson_label == lesson_label }
  end

  private def lesson_labels
    @category_assignments.values.flatten.map(&:assignable_lesson_label).uniq
  end

  #category_count_label ensures we do not double count identical assignments across sections.
  #ex: if assignment assigned to section 1 and section 2 is identical, then category_count += 1
  def category_count_label(assignment_list_for_category)
    return 0 if assignment_list_for_category.size == 0
    assignment_list_for_category
      .group_by(&:assignable)
      .collect { |_assignable, assignments| assignments.first }.size
  end
  private :category_count_label

  def populate_selected_assignables!(klass, assignments)
    assignments.select { |assignment| assignment.assignable_type == klass.to_s }
               .map(&:assignable_id).join(',')
  end

  private :populate_selected_assignables!

  def assessment_links
    assessment_links = []
    assessments = @assessments_assignments.collect(&:assignable).uniq
    assessments.each do |assessment|
      count_label = ''
      url_options = @calendar_settings.assessment_link_params
      html_options = @calendar_settings.assessment_html_options
      if @calendar_settings.is_instructor?
        url_options[:selected_activities] = assessment.id
        display_link = true
      else
        url_options[:id] = assessment.id
        display_link = display_activity_link_to_student?(assessment)
      end

      lesson_label = assessment&.lesson&.label

      name = assessment.concept.name.clone
      name.prepend("#{lesson_label}: ") if lesson_label.present?
      name << ' (varies)' unless assigned_in_all_sections?(assessment)

      assessment_links << OpenStruct.new(
        count_label: count_label,
        display_link?: display_link,
        html_options: html_options,
        name: name,
        url_options: url_options
      )
    end
    assessment_links
  end

  private def display_activity_link_to_student?(activity)
    return false if @calendar_settings.program&.supersite_junior?

    @calendar_settings.sections.any? do |section|
      activity.accessible_by_section?(section)
    end
  end

  private def assigned_in_all_sections?(activity)
    return true if @calendar_settings.sections.count == 1
    assignments_sections = @assessments_assignments.select{ |assignment| assignment.assignable == activity }.collect(&:section_id).sort
    calendar_sections = @calendar_settings.sections.collect(&:id).sort
    assignments_sections.eql?(calendar_sections)
  end

  private def populate_banks
    bank = Bank.new
    activities.each do |activity|
      if bank.concept && bank.concept != activity.concept
        store_bank(bank)
        bank = Bank.new
      end
      bank.concept ||= activity.concept
      bank.assigned_count += 1
      bank.assigned_minutes += activity.minutes_to_complete ? activity.minutes_to_complete : 10
    end
    store_bank(bank) if bank.concept
    @populated = true
  end

  private def store_bank(bank)
    bank.assigned_minutes = bank.assigned_minutes.round_up_to(5)
    self.total_minutes += bank.assigned_minutes
    self.total_activities += bank.assigned_count
    @banks << bank
  end

  private def get_section_assignments_hashes(assignments)
    activties = assignments.collect(&:assignable)
    activities.sort!{ |a,b| a.id <=> b.id}
    activities.sort! { |a,b| "#{a.class}_#{a.id}" <=> "#{b.class}_#{b.id}"}
    keys = activities.collect{ |activity| "#{activity.class}_#{activity.id}" }
    keys.compact.uniq.join(',')
  end
end
