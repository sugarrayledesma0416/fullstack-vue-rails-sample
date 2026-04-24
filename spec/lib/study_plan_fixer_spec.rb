require 'tasks/study_plan_fixer'

describe StudyPlanFixer, test_debt: true do
  # Marking as test debt because this is only used by a rake task that
  # hasn't been run in a long time. If we need to use this again we can
  # remove the test_debt flag and make sure the lib is still valid.
  describe '#fix' do
    let(:program)    { create(:program) }
    let(:unit)       { create(:unit, program_id: program.id) }
    let(:lesson)     { create(:lesson, unit: unit) }
    let(:activity)   { create(:activity, lesson: lesson, activity_type: 'study_plan_practice_test') }
    let(:creator)    { double(StudyPlanConceptsCreator, create: nil) }
    let(:readings_generator)    { double(UserReadingsGenerator, generate: nil) }
    let(:fixer)      { described_class.new }
    let(:content_object) do
      double('ContentObject',
             activity_type: 'study_plan_practice_test',
             submittable?: true,
             points_possible: 10,
             grading_method: 'auto',
             content_summary: {},
             max_attempts: 1,
             submittable: {})
    end

    before do
      allow(StudyPlanConceptsCreator).to receive(:new) { creator }
      allow(UserReadingsGenerator).to receive(:new) { readings_generator }
    end

    context 'when there are no study plan practice test activities' do
      it 'does not create any study plan concepts' do
        expect(StudyPlanConceptsCreator).not_to receive(:new)
        fixer.fix
      end
    end

    context 'when there are study plan practice test activities' do
      before do
        allow_any_instance_of(Activity).to receive(:content_object).and_return(content_object)
        allow(activity).to receive(:ensure_correct_version).and_return(activity)
      end

      context 'when activity already has study plan concepts' do
        it 'does not create any extra study plan concepts' do
          create(:study_plan_concept,
                  activity: activity,
                  program_id: program.id,
                  cms_revision_id: activity.cms_revision_id)
          expect(StudyPlanConceptsCreator).not_to receive(:new)
          fixer.fix
        end
      end

      context 'when activity has study plan concepts for a different version of the activity' do
        it 'creates study plan concepts for the activity' do
          create(:study_plan_concept,
                  activity: activity,
                  program_id: program.id,
                  cms_revision_id: activity.cms_revision_id + 1)
          expect(StudyPlanConceptsCreator).to receive(:new)
          fixer.fix
        end
      end

      context 'when activity already does not have study plan concepts' do
        it 'creates study plan concepts for the activity' do
          activity
          expect(StudyPlanConceptsCreator).to receive(:new)
          fixer.fix
        end
      end
    end

    context 'when there are no attempts made on any activity' do
      it 'does not instantiate StudyPlanPracticeReadingsFixer' do
        expect(UserReadingsGenerator).not_to receive(:new)
        fixer.fix
      end
    end

    context "when there are attempts made on an activity, but it's not been completed" do
      it 'does not instantiate StudyPlanPracticeReadingsFixer' do
        create(:attempt, activity: activity, status_code: AttemptStatus::CODE_OPENED)
        expect(UserReadingsGenerator).not_to receive(:new)
        fixer.fix
      end
    end

    context 'when there are completed attempts made on a study_plan_practice_test activity' do
      it 'instantiates UserReadingsGenerator' do
        student = create(:student)
        attempt = create(:attempt, activity: activity,
                                    status_code: AttemptStatus::CODE_COMPLETED,
                                    user: student)

        # Assign results
        allow_any_instance_of(Attempt).to receive(:results)
          .and_return(MaestroActivityEngine::ActivityContent::Results.new)

        allow_any_instance_of(Activity).to receive(:content_object).and_return(content_object)

        expect(UserReadingsGenerator).to receive(:new)
          .with(activity, attempt.results, attempt.section, student)

        fixer.fix
      end

      it 'ignores all attempts that needs to be migrated to the API datastore' do
        student = create(:student)
        attempt = create(:attempt, activity: activity,
                                    status_code: AttemptStatus::CODE_COMPLETED,
                                    user: student)

        # Assign results
        allow_any_instance_of(Attempt).to receive(:results)
          .and_return(MaestroActivityEngine::ActivityContent::Results.new)
        allow_any_instance_of(Attempt).to receive(:submission_migration_needed?).and_return(true)

        expect(UserReadingsGenerator).not_to receive(:new)
          .with(activity, attempt.results, attempt.section, student)

        fixer.fix
      end

      it 'ignores all attempts that belongs to archived users' do
        student = create(:student, archived: 1)
        attempt = create(:attempt, activity: activity,
                                    status_code: AttemptStatus::CODE_COMPLETED,
                                    user: student)

        # Assign results
        allow_any_instance_of(Attempt).to receive(:results)
          .and_return(MaestroActivityEngine::ActivityContent::Results.new)

        allow_any_instance_of(Activity).to receive(:content_object).and_return(content_object)

        expect(UserReadingsGenerator).not_to receive(:new)
          .with(activity, attempt.results, attempt.section, student)

        fixer.fix
      end

      it 'does not ignore all attempts that belongs to active users' do
        student = create(:student, archived: 0)
        attempt = create(:attempt, activity: activity,
                                    status_code: AttemptStatus::CODE_COMPLETED,
                                    user: student)

        # Assign results
        allow_any_instance_of(Attempt).to receive(:results)
          .and_return(MaestroActivityEngine::ActivityContent::Results.new)

        allow_any_instance_of(Activity).to receive(:content_object).and_return(content_object)

        expect(UserReadingsGenerator).to receive(:new)
          .with(activity, attempt.results, attempt.section, student)

        fixer.fix
      end

      it 'only retrieves the activities with missing study plan concepts' do
        allow_any_instance_of(Activity).to receive(:content_object).and_return(content_object)
        allow_any_instance_of(Attempt).to receive(:results)
          .and_return(MaestroActivityEngine::ActivityContent::Results.new)

        student = create(:student)
        common_cms_revision_id = 1
        activity_with_concepts = create(:activity,
                                        lesson: lesson,
                                        cms_revision_id: common_cms_revision_id,
                                        activity_type: 'study_plan_practice_test')

        create(:study_plan_concept,
               activity: activity_with_concepts,
               program_id: program.id,
               cms_revision_id: common_cms_revision_id)

        attempt_1 = create(:attempt,
                           activity: activity,
                           status_code: AttemptStatus::CODE_COMPLETED,
                           user: student)

        attempt_2 = create(:attempt,
                           activity: activity_with_concepts,
                           status_code: AttemptStatus::CODE_COMPLETED,
                           user: student)

        expect(UserReadingsGenerator).to receive(:new)
          .with(activity, attempt_1.results, attempt_1.section, student)

        expect(UserReadingsGenerator).not_to receive(:new)
          .with(activity_with_concepts, attempt_2.results, attempt_2.section, student)

        fixer.fix
      end
    end

    context 'when there are completed attempts made on a practice_test activity' do
      it 'does not instantiate UserReadingsGenerator' do
        student = create(:student)
        attempt = create(:attempt, activity: activity,
                                    status_code: AttemptStatus::CODE_COMPLETED,
                                    user: student)
        allow(content_object).to receive(:activity_type).and_return('practice_test')
        allow_any_instance_of(Activity).to receive(:content_object).and_return(content_object)
        expect(UserReadingsGenerator).to_not receive(:new)
          .with(activity, attempt.results, attempt.section, student)
        fixer.fix
      end
    end
  end
end
