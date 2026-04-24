class Workset < ApplicationRecord
  LAST_ACTIVITY = 'last_activity'
  belongs_to :user
  belongs_to :section

  validates_presence_of :user_id, :section_id, :activity_list

  def self.current(user, section, activity = nil)
    workset = where(user_id: user.id, section_id: section.id).first

    if workset && activity
      return nil unless workset.index_in_set(activity)
    end

    workset
  end

  def self.create_or_update(user, section, activity_list)
    @workset = current(user, section)
    if @workset
      @workset.activity_list = activity_list
    else
      @workset = Workset.new(:user => user, :section => section, :activity_list => activity_list)
    end
    @workset.save!
  end

  def activities
    # need to re-sort to match activity_list order since find_by_id may return
    # records in a different order than our bank/assignment_day specifies
    @activities ||= Activity.where(id: activity_ids)
                            .includes(concept: :lesson)
                            .order(activity_sort_sql)
  end

  def grouped_activities(sort_by_assignment_group)
    current_group = ""
    activities_and_assignments.inject([]) do |result, (activity, assignment)|
      group_name = if sort_by_assignment_group
                     activity.assignment_group ? activity.assignment_group : nil
                   else
                     activity.concept.name ? activity.concept.name : nil
                   end

      if group_name != current_group
        result.push({ :name => group_name,
                      :assignments => [[activity, assignment]] })
        current_group = group_name
      else
        result.last[:assignments].push([activity, assignment])
      end
      result
    end
  end

  def assignments
    @assignments ||= Assignment.by_section(section).by_activities(*activities).includes(:category).each { |a| a.section = section }
  end

  def activities_and_assignments
    @activities_and_assignments ||= activities.inject([]) do |memo, activity|
      assignment = assignment_by_activity(activity)
      memo << [ activity, assignment ]  if assignment
      memo
    end
  end

  def assignment_by_activity(activity)
    assignments.detect { |a| a.assignable_id == activity.id }
  end

  def attempts
    @attempts ||= Attempt.attempts_for_activities(user, section, activities)
  end

  def attempt(activity)
    attempts[activity.id]
  end

  def overdue?(activity, assignment)
    assignment.late?(Time.zone.now) && attempt(activity).unsubmitted?
  end

  def index_in_set(activity)
    activity_ids.index(activity.id.to_s)
  end

  def final_activity?(current_activity)
    index_in_set(current_activity) == activity_ids.length - 1
  end

  def next_activity(current_activity)
    current_index = index_in_set(current_activity)
    return unless current_index

    next_activity_id = activity_ids.at(current_index + 1)
    if next_activity_id
      Activity.find(next_activity_id)
    else
      LAST_ACTIVITY
    end
  end

  def total_minutes
    mins = 0
    unless activities.nil?
      activities.each do | activity |
        unless activity.minutes_to_complete.nil?
          mins += activity.minutes_to_complete
        end
      end
    end
    mins
  end

  def activities_count
    activities.count
  end

  private def activity_sort_sql
    Arel.sql(
      self.class.sanitize_sql_array(
        ['find_in_set(activities.id, ?)', activity_list]
      )
    )
  end

  private def activity_ids
    @activity_ids ||= activity_list.split(',')
  end
end
