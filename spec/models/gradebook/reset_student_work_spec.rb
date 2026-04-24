describe Gradebook::ResetStudentWork do
  let(:student) { create(:student) }
  let(:course) { create(:course) }
  let(:section) { create(:section, course: course) }
  let(:lesson) { create(:lesson_with_toc_entries) }
  let(:toc_location) { create(:toc_entry) }

  let(:activity) do
    create(:activity, lesson: lesson, toc_location: toc_location)
  end

  let!(:attempt) do
    create(:attempt,
           user: student,
           section: section,
           activity: activity)
  end

  before do
    section.students << student
    allow(lesson).to receive(:strand_for_toc_location).and_return(toc_location)
    allow(Attempt).to receive(:reset_attempt).and_call_original
  end

  it 'removes related help requests' do
    another_student = create(:student)
    another_section = create(:section, course: course)
    another_activity = create(:activity)

    create(:help_request, user_id: student.id,
                          activity_id: activity.id,
                          section_id: section.id)
    help_request_from_another_section = create(:help_request,
                                               user_id: student.id,
                                               activity_id: activity.id,
                                               section_id: another_section.id)
    help_request_for_another_activity = create(:help_request,
                                               user_id: student.id,
                                               activity_id: another_activity.id,
                                               section_id: section.id)
    help_request_from_another_student = create(:help_request,
                                               user_id: another_student.id,
                                               activity_id: activity.id,
                                               section_id: section.id)
    valid_help_requests = [help_request_from_another_section,
                           help_request_for_another_activity,
                           help_request_from_another_student]

    expect do
      Gradebook::ResetStudentWork.new(activity.id, section.id, student.id).process
    end.to change { HelpRequest.count }.by(-1)

    expect(HelpRequest.all).to match(valid_help_requests)
  end

  it 'will reset the attempt' do
    expect(Attempt).to receive(:reset_attempt).with(student, section, activity)
    Gradebook::ResetStudentWork.new(activity.id, section.id, student.id)
                               .process
  end

  it 'removes an associated RubricCriteriaScore record' do
    rubric_score = create(:rubric_criteria_score, attempt_id: attempt.id)
    expect do
      described_class.new(activity.id, section.id, student.id).process
    end.to change { RubricCriteriaScore.count }.by(-1)
  end

  context 'when resetting a study plan' do
    context 'when an activity is not a study plan practice test' do
      it 'does not delete existing user readings for the activity' do
        expect do
          Gradebook::ResetStudentWork.new(activity.id, section.id, student.id).process
        end.not_to change { UserReading.count }
      end
    end

    context 'when an activity is a study plan practice test' do
      let!(:another_student) { create(:student) }
      let(:notifications) { double('notifications', dispatch: nil) }

      let(:activity_2) do
        create(:activity,
               lesson: lesson,
               toc_location: toc_location,
               activity_type: 'study_plan_practice_test')
      end

      let(:study_plan_1) { create(:study_plan_concept, activity: activity_2) }
      let(:study_plan_2) { create(:study_plan_concept, activity: activity_2) }

      let(:concept_1_recommendation) do
        create(:recommendation, study_plan_concept: study_plan_1)
      end

      let(:concept_2_recommendation) do
        create(:recommendation, study_plan_concept: study_plan_2)
      end

      before do
        create(:user_reading,
               user_id: student.id,
               recommendation: concept_1_recommendation)
        create(:user_reading,
               user_id: student.id,
               recommendation: concept_2_recommendation)
        create(:user_reading,
               user_id: another_student.id,
               recommendation: concept_2_recommendation)

        allow(Activity).to receive(:find).and_return(activity_2)
        allow(activity_2).to receive(:notifications).and_return(notifications)
      end

      it 'deletes existing user readings for the activity' do
        expect(UserReading.count).to eq 3
        Gradebook::ResetStudentWork.new(activity_2.id, section.id, student.id)
                                   .process
        expect(UserReading.count).to eq 1
        expect(UserReading.first.user_id).to eq another_student.id
      end

      it 'dispatches a notification regarding the study plan being reset' do
        expect(notifications).to receive(:dispatch)
          .with('StudyPlanReset', section: section, user: student)
        Gradebook::ResetStudentWork.new(activity_2.id, section.id, student.id)
                                   .process
      end
    end

    context 'when an activity is a diagnostic v2' do
      let!(:another_student) { create(:student) }
      let(:notifications) { double('notifications', dispatch: nil) }

      let(:diag_v2_activity) do
        create(:activity,
               lesson: lesson,
               toc_location: toc_location,
               activity_type: 'diagnostic_v2')
      end

      let(:study_plan_1) { create(:study_plan_concept, activity: diag_v2_activity) }
      let(:study_plan_2) { create(:study_plan_concept, activity: diag_v2_activity) }

      let(:concept_1_recommendation) do
        create(:recommendation, study_plan_concept: study_plan_1)
      end

      let(:concept_2_recommendation) do
        create(:recommendation, study_plan_concept: study_plan_2)
      end

      before do
        create(:user_reading,
               user_id: student.id,
               recommendation: concept_1_recommendation)
        create(:user_reading,
               user_id: student.id,
               recommendation: concept_2_recommendation)
        create(:user_reading,
               user_id: another_student.id,
               recommendation: concept_2_recommendation)

        allow(Activity).to receive(:find).and_return(diag_v2_activity)
        allow(diag_v2_activity).to receive(:notifications).and_return(notifications)
      end

      it 'deletes existing user readings for the activity' do
        expect(UserReading.count).to eq 3
        Gradebook::ResetStudentWork.new(diag_v2_activity.id, section.id, student.id)
                                   .process
        expect(UserReading.count).to eq 1
        expect(UserReading.first.user_id).to eq another_student.id
      end

      it 'dispatches a notification regarding the study plan being reset' do
        expect(notifications).to receive(:dispatch)
          .with('StudyPlanReset', section: section, user: student)
        Gradebook::ResetStudentWork.new(diag_v2_activity.id, section.id, student.id)
                                   .process
      end
    end
  end
end
