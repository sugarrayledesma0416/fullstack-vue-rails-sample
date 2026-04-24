require 'set'

namespace :gradebook do
  desc "load test data from live course dump"
  task load_test_data: :environment do
    raise 'only use this in benchmark env' unless Rails.env.benchmark?
    Gradebook::Section.delete_all
    Gradebook::Category.delete_all
    Gradebook::AssignmentActivity.delete_all
    Gradebook::ScoreAction.delete_all

    Course.includes(:categories, :sections).each do |course|
      Gradebook::Section.transaction do
        columns = [:m3_section_id, :due_time]
        Gradebook::Section.import columns,
                                  course.sections.map { |section| [section.id, section.due_time] },
                                  validate: false
        puts "#{ Time.now }: did first section import (course #{ course })"
      end

      Gradebook::Category.transaction do
        columns = [:m3_category_id, :m3_section_id, :current_state]
        categories = Category.all.map do |category|
          [category.id, nil,
           category.attributes.slice(*%w{max_attempts weighting_percent accept_late_work
                                                       drop_low_score credit_only penalty_percent
                                                       late_work_penalty}).to_json]
        end
        Gradebook::Category.import columns, categories, validate: false
        puts "#{ Time.now }: did first category import (course #{ course })"
      end
    end

    assignment_activities = Assignment.includes(:assignable).map do |assignment|
      assignment_state = assignment.attributes.slice(*%w{ custom_due_time })
      activity_state = assignment.assignable.attributes.slice(*%w{points_possible grading_method submittable? max_attempts})
      current_state = assignment_state.merge(activity_state)
      activity = assignment.assignable
      [assignment.assignable_id,
       activity.respond_to?(:concept_id) ? activity.concept_id : activity.toc_location,
       activity.lesson_id,
       assignment.due_date,
       Week.week_containing(assignment.due_date),
       assignment.category_id,
       current_state.to_json,
       assignment.section_id]
    end

    activity_points_possible = Activity.all.each_with_object({}) do |activity, memo|
      memo[activity.id] = activity.points_possible
    end

    Gradebook::AssignmentActivity.transaction do
      columns = [:activity_id, :strand_id, :lesson_id, :day_id, :week_id, :category_id, :current_state, :section_id]
      Gradebook::AssignmentActivity.import columns, assignment_activities, validate: false
      puts "#{ Time.now }: did first assignment activity import"
    end

    Gradebook::ScoreAction.transaction do
      columns = [:user_id, :activity_id, :section_id, :action, :summation]
      score_actions = Score.all.map do |score|
        points_possible = activity_points_possible[score.scorable_id]
        summation = score.attributes.slice(*%w{ points_earned points_pending attempt_count })
        points_earned, points_pending = %w{points_earned points_pending}.map { |key| summation[key] }
        net_points_earned = points_earned
        net_points_possible = points_possible
        [score.user_id,
         score.scorable_id,
         score.section_id,
         '{}',
         summation.merge(net_points_earned: net_points_earned,
                         net_points_possible: net_points_possible,
                         points_possible: points_possible).to_json]
      end
      Gradebook::ScoreAction.import columns, score_actions, validate: false
      puts "#{ Time.now }: score action: did first import"
    end

    category_ids = Category.all.map(&:id)
    activity_ids = Assignment.all.map(&:assignable_id).uniq
    section_ids = Section.all.map(&:id).uniq
    category_id_selection = (1..391615).to_a - category_ids
    section_id_selection = (124677..421309).to_a - section_ids
    activity_id_selection = (1..108817).to_a - activity_ids

    Gradebook::Section.transaction do
      sections = (1..185000).map { [section_id_selection.sample, '12:00:00'] }
      columns = [:m3_section_id, :due_time]
      Gradebook::Section.import columns, sections, validate: false
      puts "#{ Time.now }: section: did second import"
    end
    Gradebook::Category.transaction do
      categories = (1..384000).map { [category_id_selection.sample,
                                    section_id_selection.sample,
                                    '{}'] }
      columns = [:m3_category_id, :m3_section_id, :current_state]
      Gradebook::Category.import columns, categories, validate: false
      puts "#{ Time.now }: category: did second import"
    end

    (1..32).each do |n|
      Gradebook::AssignmentActivity.transaction do
        strand_id_selection = (39000..146000).to_a
        lesson_id_selection = (1..685).to_a
        columns = [:activity_id, :strand_id, :lesson_id, :day_id, :week_id, :category_id, :current_state, :section_id]
        assignment_activities = 100000.times.map do [activity_id_selection.sample,
                                                     strand_id_selection.sample,
                                                     lesson_id_selection.sample,
                                                     '2016-06-06',
                                                     '2016-06-05',
                                                     category_id_selection.sample,
                                                     '{}',
                                                     section_id_selection.sample] end
        Gradebook::AssignmentActivity.import columns, assignment_activities, validate: false
        puts "#{ Time.now }: assignment activity, second import: #{ n*100000 } added"
      end
    end

    (1..500).each do |n|
      Gradebook::ScoreAction.transaction do
        user_id_selection = (3..3537568).to_a
        columns = [:user_id, :activity_id, :section_id, :action, :summation]
        score_actions = (1..100000).map { [user_id_selection.sample,
                                         activity_id_selection.sample,
                                         section_id_selection.sample,
                                         '{}',
                                         '{}'] }
        Gradebook::ScoreAction.import columns, score_actions, validate: false
        puts "#{ Time.now }: score action, second import: #{ n*100000 } added"
      end
    end
  end
end
