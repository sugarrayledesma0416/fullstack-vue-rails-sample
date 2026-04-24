class StudyPlanConceptsCreator
  attr_accessor :activity, :program_id

  delegate :cms_revision_id, :content_object, to: :activity
  delegate :id, to: :activity, prefix: true, allow_nil: true

  def initialize(activity, program_id)
    self.activity = activity
    self.program_id = program_id
  end

  def self.batch_create(activities, program_id)
    activities.each do |activity|
      program_id = (activity.persisted? && activity.program && activity.program.id) || program_id
      new(activity, program_id).create
    end
  end

  def create
    unless concepts_in_place?
      study_plan_concepts_attributes.each do |study_plan_concept_attributes|
        StudyPlanConcept.create!(study_plan_concept_attributes)
      end
    end
  end

  private def concepts_in_place?
    StudyPlanConcept.where(
      activity_id: activity.id,
      cms_revision_id: activity.cms_revision_id,
      program_id: program_id
    ).exists?
  end

  private def study_plan_concepts_attributes
    activity_concepts.map do |concept|
      base_attributes.merge(concept_attributes(concept))
    end
  end

  private def activity_concepts
    @activity_concepts ||= content_object.concepts
  end

  private def concept_attributes(concept)
    {
      reference_id: concept.ref,
      title: concept.title,
      threshold: concept.threshold,
      recommendations_attributes: recommendations_attributes(concept)
    }
  end

  private def recommendations_attributes(concept)
    vocabulary_reference(concept) +
    reference_attributes(concept.external_references, 'reference') +
    reference_attributes(concept.supplemental_activities, 'supplemental')
  end

  private def reference_attributes(references, type)
    references.map do |reference|
      {
        recommendation_type: type,
        cms_activity_id: reference.activity,
        title: reference.title
      }
    end
  end

  private def vocabulary_reference(concept)
    return [] unless concept.vocabulary_link_label

    [{
      recommendation_type: 'vocabulary',
      title: concept.vocabulary_link_label
    }]
  end

  private def base_attributes
    @base_attributes ||= {
      activity_id: activity_id,
      cms_revision_id: cms_revision_id,
      program_id: program_id
    }
  end
end
