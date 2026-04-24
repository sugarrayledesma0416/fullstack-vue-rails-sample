describe MixAndMatchAssessmentPresenter do
  include Rails.application.routes.url_helpers

  let(:course) { create(:course) }
  let(:program) { create(:program) }
  let(:unit) { create(:unit, program:) }
  let(:lesson_1) { create(:lesson, unit:) }
  let(:lesson_2) { create(:lesson, unit:) }

  # Create three strands in lesson 1. One is a non-assessment strand,
  # the other two are assessment strands.
  # Also create an assessment strand in lesson 2.
  # Create activities in all the strands. This will allow verifying
  # that only the activities in the assessment strands of the specified
  # lesson appear.
  let(:non_assessment_strand) do
    create(:toc_entry, assessment: false, title: 'non-assessment')
  end

  let(:non_assessment_concept) do
    create_concept_from_strand(non_assessment_strand, lesson_1)
  end

  let(:strand_1) do
    create(:toc_entry, assessment: true, title: 'L1 quizzes')
  end

  let(:concept_1) do
    create_concept_from_strand(strand_1, lesson_1)
  end

  let(:strand_2) do
    create(:toc_entry, assessment: true, title: 'L1 tests')
  end

  let(:concept_2) do
    create_concept_from_strand(strand_2, lesson_1)
  end

  let(:other_lesson_strand) do
    create(:toc_entry, assessment: true, title: 'L2 quizzes')
  end

  let(:other_lesson_concept) do
    create_concept_from_strand(other_lesson_strand, lesson_2)
  end

  let(:instructor) { create(:instructor) }

  let(:s1_assessment) do
    create(
      :activity,
      activity_type: 'exam',
      concept: concept_1,
      icon: 'audio,textbook',
      lesson: lesson_1,
      toc_location: strand_1.location
    )
  end

  let(:s2_assessment) do
    create(
      :activity,
      activity_type: 'exam',
      concept: concept_2,
      icon: 'audio',
      lesson: lesson_1,
      toc_location: strand_2.location
    )
  end

  let(:presenter) do
    described_class.new(
      course_id: course.id,
      current_assessment_id: nil,
      lesson_id: lesson_1.id,
      program_id: program.id,
      current_user: instructor
    )
  end

  def create_concept_from_strand(strand, lesson)
    # In some programs, the concept name is the singular version of
    # the strand title. The plural name, from the strand, is what
    # should be returned. Set the singular name here to be able to
    # verify the returned value comes from the strand, not the concept.
    create(
      :concept,
      assessment: strand.assessment?,
      id: strand.location,
      lesson:,
      name: strand.title.singularize
    )
  end

  before do
    lesson_1.toc_entries = [
      non_assessment_strand,
      strand_1,
      strand_2
    ]
    lesson_1.save!

    lesson_2.toc_entries = [other_lesson_strand]
    lesson_2.save!

    # Trigger the let statements for these. Needs to be done
    # after lesson toc entries are saved, so a let! will not work.
    s1_assessment
    s2_assessment

    # activity in lesson 1 non-assessment strand
    create(
      :activity,
      concept: non_assessment_concept,
      lesson: lesson_1,
      toc_location: non_assessment_strand.location
    )
    # activity in lesson 2 assessment strand
    create(
      :activity,
      concept: other_lesson_concept,
      lesson: lesson_2,
      toc_location: other_lesson_strand.location
    )
  end

  describe '#activity_data' do
    def activity_list
      presenter.activity_data.flat_map do |strand|
        strand[:activities].map { |activity| activity.slice(:id, :title) }
      end
    end

    def activity_ids
      activity_list.pluck(:id)
    end

    it 'returns vhl-created activities for the specified lesson, only if ' \
       'they are in an assessment strand' do
      expect(activity_list).to contain_exactly(
        { id: s1_assessment.id, title: s1_assessment.title },
        { id: s2_assessment.id, title: s2_assessment.title }
      )
    end

    it 'excludes activities that have a concept but no strand (orphaned ' \
       'activities due to strand deletion' do
      orphaned_concept = create(
        :concept,
        assessment: true,
        lesson: lesson_1
      )
      create(
        :activity,
        concept: orphaned_concept,
        lesson: lesson_1,
        toc_location: orphaned_concept.id
      )

      expect(activity_list).to contain_exactly(
        { id: s1_assessment.id, title: s1_assessment.title },
        { id: s2_assessment.id, title: s2_assessment.title }
      )
    end

    it 'excludes vhl-created non-exam activities even if they are in an assessment strand' do
      create(
        :activity,
        activity_type: 'audio_composition',
        concept: concept_1,
        lesson: lesson_1,
        toc_location: strand_1.location
      )

      expect(activity_ids).to contain_exactly(
        s1_assessment.id, s2_assessment.id
      )
    end

    context 'when instructor-created assessments exist,' do
      before do
        allow(Maestro::LicenseGroup).to receive(:all).and_return([])
      end

      let(:instructor_created_assessment) do
        create(
          :instructor_created_activity,
          activity_type: 'exam',
          concept: concept_1,
          lesson: lesson_1,
          process_as_assessment: true,
          toc_location: strand_1.location,
          instructor:
        )
      end

      it 'returns instructor-created activities for the specified lesson ' \
         'if they belongs to the current user' do
        instructor_created_assessment
        expect(activity_ids).to match_array(
          [s1_assessment.id, s2_assessment.id, instructor_created_assessment.id]
        )
      end

      it 'does not return instructor-created activities of any other intructor than the current user' do
        instructor_created_assessment
        other_instructor = create(:instructor)
        other_instructor_created_assessment = create(
          :instructor_created_activity,
          activity_type: 'exam',
          concept: concept_1,
          lesson: lesson_1,
          process_as_assessment: true,
          toc_location: strand_1.location,
          instructor: other_instructor
        )

        expect(activity_ids).not_to include(other_instructor_created_assessment.id)
      end

      it 'does not return instructor-created activities that were previously removed' do
        removed_course_assessment = create(
          :instructor_created_activity,
          activity_type: 'exam',
          concept: concept_1,
          lesson: lesson_1,
          process_as_assessment: true,
          toc_location: strand_1.location,
          hide_from_my_content: true,  # The flag that manages IGC deletion
          instructor:
        )

        expect(activity_ids).not_to include(removed_course_assessment.id)
      end
    end

    it 'sorts the activities by concept rank, then activity rank in concept' do
      concept_1.update!(rank: 2)
      concept_2.update!(rank: 1)
      other_strand_1_activity = create(
        :activity,
        activity_type: 'exam',
        concept: concept_1,
        lesson: lesson_1,
        toc_location: strand_1.location,
        toc_location_rank: 1
      )
      s1_assessment.update!(toc_location_rank: 2)

      expect(activity_ids).to eq(
        [s2_assessment.id, other_strand_1_activity.id, s1_assessment.id]
      )
    end

    it 'excludes a vhl-created exam activity if it is the current activity' do
      presenter.current_assessment_id = s1_assessment.id
      expect(activity_ids).to eq([s2_assessment.id])
    end

    it 'returns icon information for each activity' do
      expect(presenter.activity_data).to contain_exactly(
        hash_including(
          id: concept_1.id,
          activities: match_array(
            [
              hash_including(
                icons: %w[audio textbook],
                id: s1_assessment.id
              )
            ]
          )
        ),
        hash_including(
          id: concept_2.id,
          activities: match_array(
            [
              hash_including(
                icons: %w[audio],
                id: s2_assessment.id
              )
            ]
          )
        )
      )
    end

    it 'returns the activities grouped by strand, including strand id, strand name, and concept name for each group' do
      expect(presenter.activity_data).to contain_exactly(
        hash_including(
          id: concept_1.id,
          name: strand_1.title,
          concept_name: concept_1.name,
          activities: match_array(
            [hash_including(id: s1_assessment.id, title: s1_assessment.title)]
          )
        ),
        hash_including(
          id: concept_2.id,
          name: strand_2.title,
          concept_name: concept_2.name,
          activities: match_array(
            [hash_including(id: s2_assessment.id, title: s2_assessment.title)]
          )
        )
      )
    end

    it 'returns a url property for each activity with the mix and match ' \
       'assessment path for that activity' do
    end
  end
end
