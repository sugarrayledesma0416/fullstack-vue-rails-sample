class DueDate
  attr_accessor :due_date, :last_concept_id, :section_id, :query_builder, :user_id

  def initialize(section_id, due_date, user_id)
    self.section_id = section_id
    self.user_id= user_id
    self.due_date = due_date
    self.last_concept_id = nil
  end

  def serialize
    {
      assignment_groups: assignment_groups.map(&:serialize),
      due_date: due_date
    }
  end

  def assignment_groups
    @assignment_groups ||= build_assignment_groups
  end

  def build_assignment_groups
    query_builder.assignments_for(due_date).inject([]) { |memo, assignment|
      if memo.empty? || (memo.last.concept_id != assignment.concept_id) || is_assessment?(assignment)
       memo << AssignmentGroup.new(
         concept_label: assignment.concept_name,
         student_title: assignment.student_title,
         concept_color: assignment.concept_color,
         concept_id: assignment.concept_id,
         concept_media_item_id: assignment.concept_media_item_id,
         lesson_name: assignment.lesson_name,
         section_id: section_id,
         is_assessment: is_assessment?(assignment),
         assessment_id: assignment.assignable_id
       )
      end
      memo.last << assignment
      memo
    }.inject([[], true]) { |memo, assignment_group|
      if memo[1] && assignment_group.incomplete?
        assignment_group.mark_as_recommended!
        memo[1] = false
      end
      memo[0] << assignment_group
      memo
    }[0]
  end
  private :build_assignment_groups

  def is_assessment?(assignment)
    assignment.concept_is_assessment == 1
  end
  private :is_assessment?

  def query_builder
    @query_builder ||= QueryBuilder.new(user_id, section_id)
  end
  private :query_builder

  class QueryBuilder
    include IndividualAssignmentQueryable

    attr_accessor :user_id, :section_id

    def initialize(user_id, section_id)
      self.user_id = user_id
      self.section_id = section_id
    end

    def assignments_for(due_date)
      base_scope.where(
        [
          'COALESCE(individual_assignments.due_date, assignments.due_date) = ?',
          due_date
        ]
      ).sort_by(&:rank)
    end

    ASSIGNMENT_SELECT_STATEMENT = <<~SQL.freeze
      assignments.section_id,
      activities.title,
      activities.student_title,
      COALESCE(asa.assignment_set_rank, assignments.rank) as rank,
      assignments.assignable_id,
      activities.lesson_id,
      activities.concept_id,
      concepts.name as concept_name,
      concepts.assessment as concept_is_assessment,
      concepts.media_item_id as concept_media_item_id,
      if(lessons.label != '', lessons.label, lessons.name) as lesson_name,
      attempts.status_code,
      concepts.background_color as concept_color
    SQL

    private def base_scope
      apply_individual_assignment_filter(Assignment.by_type(Activity), user_id)
        .select(ASSIGNMENT_SELECT_STATEMENT).joins(
          'LEFT OUTER JOIN attempts ON attempts.section_id = assignments.section_id ' \
          "AND attempts.activity_id = activities.id AND attempts.user_id = #{user_id} " \
          "AND attempts.status_code <> #{AttemptStatus::CODE_RESET}"
        ).joins(AssignmentSorter::ASSIGNMENT_JOINS).where(
          assignments: { section_id: section_id }
        ).order(Arel.sql(AssignmentSorter::ASSIGNMENT_ORDER))
    end
  end

  class AssignmentGroup
    attr_accessor :completed_count, :assigned_count, :concept_label,
                  :concept_color, :concept_id, :concept_media_item_id,
                  :section_id, :is_assessment, :due_date,
                  :assessment_id, :ranks, :lesson_name, :recommended,
                  :student_title

    def initialize(params = {})
      self.concept_label = params[:concept_label]
      self.concept_color = params[:concept_color]
      self.section_id = params[:section_id]
      self.concept_id = params[:concept_id]
      self.concept_media_item_id = params[:concept_media_item_id]
      self.is_assessment = params[:is_assessment]
      self.assessment_id = params[:assessment_id]
      self.lesson_name = params[:lesson_name]
      self.completed_count = 0
      self.assigned_count = 0
      self.ranks = []
      self.recommended = false
      self.student_title = params[:student_title]
    end

    def concept_media_item
      return @concept_media_item if defined?(@concept_media_item)

      @concept_media_item = concept_media_item_id && MediaItem.find(concept_media_item_id)
    end

    def complete?
      status == 'complete'
    end

    def partial?
      status == 'partial'
    end

    def not_started?
      status == 'not started'
    end

    def status
      if completed_count == 0
        'not started'
      elsif completed_count < assigned_count
        'partial'
      else
        'complete'
      end
    end

    def incomplete?
      completed_count != assigned_count
    end

    def incomplete_count
      assigned_count - completed_count
    end

    def mark_as_recommended!
      self.recommended = true
    end

    def serialize
      {
        status: status,
        color: concept_color,
        title: concept_label
      }
    end

    def link_label
      # We split on <br/> for VOL programs that have long
      # concept names. e.g: D'accord 2019 Prime titles.
      # and only precede with the lesson name if assignment is not
      # an assessment with student title
      if is_assessment && student_title.present?
        student_title.to_s.split('<br/>').first
      else
        "#{lesson_name} : #{concept_label.to_s.split('<br/>').first}"
      end
    end

    def rank_range
      "#{ranks.min}..#{ranks.max}"
    end

    def <<(assignment)
      if [AttemptStatus::CODE_SUBMITTED, AttemptStatus::CODE_COMPLETED].include? assignment.status_code
        self.completed_count += 1
      end
      self.assigned_count += 1
      self.ranks << assignment.rank
    end
  end
end
