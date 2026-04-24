describe Cartridge::GradePassback do
  let(:student) { create(:student) }
  let(:attempt) { create(:attempt) }
  let(:consumer_guid) { SecureRandom.uuid }
  let(:platform_guid) { SecureRandom.uuid }
  let(:grade_params) do
    {
      consumer_guid: consumer_guid,
      platform_guid: platform_guid
    }
  end
  let(:basic_outcome_service_grade_passback_strategy) do
    instance_double(Cartridge::BasicOutcomeServiceGradePassbackStrategy)
  end
  let(:assignment_and_grade_service_grade_passback_strategy) do
    instance_double(Cartridge::AssignmentAndGradeServiceGradePassbackStrategy)
  end
  let(:grade_passback) do
    described_class.new(student, attempt, grade_params)
  end

  before do
    allow(Cartridge::BasicOutcomeServiceGradePassbackStrategy)
      .to receive(:new)
      .and_return(basic_outcome_service_grade_passback_strategy)
    allow(basic_outcome_service_grade_passback_strategy)
      .to receive(:post_grade)

    allow(Cartridge::AssignmentAndGradeServiceGradePassbackStrategy)
      .to receive(:new)
      .and_return(assignment_and_grade_service_grade_passback_strategy)
    allow(assignment_and_grade_service_grade_passback_strategy)
      .to receive(:post_grade)

    allow(VHLMonitor).to receive(:error)
  end

  describe '#process' do
    context 'when the Lti version is blank,' do
      it 'post the grade using a basic outcome service grade passback strategy' do
        grade_passback.process

        expect(Cartridge::BasicOutcomeServiceGradePassbackStrategy)
          .to have_received(:new)
          .with(student, attempt, consumer_guid: consumer_guid)

        expect(basic_outcome_service_grade_passback_strategy)
          .to have_received(:post_grade)
      end
    end

    context 'when the Lti version is legacy Lti 1.1,' do
      let(:grade_params) do
        super().merge(lti_version: Cartridge::LaunchesController::LEGACY_LTI_VERSION)
      end

      it 'post the grade using a basic outcome service grade passback strategy' do
        grade_passback.process

        expect(Cartridge::BasicOutcomeServiceGradePassbackStrategy)
          .to have_received(:new)
          .with(student, attempt, consumer_guid: consumer_guid)

        expect(basic_outcome_service_grade_passback_strategy)
          .to have_received(:post_grade)
      end
    end

    context 'when the Lti version is Lti 1.3,' do
      let(:grade_params) do
        super().merge(lti_version: Cartridge::LaunchesController::LATEST_LTI_VERSION)
      end

      it 'post the grade using an AGS grade passback strategy' do
        grade_passback.process

        expect(Cartridge::AssignmentAndGradeServiceGradePassbackStrategy)
          .to have_received(:new)
          .with(student, attempt, platform_guid: platform_guid)

        expect(assignment_and_grade_service_grade_passback_strategy)
          .to have_received(:post_grade)
      end
    end

    context 'when the Lti version is unsupported,' do
      let(:grade_params) do
        super().merge(lti_version: 'unsupported version')
      end

      it 'does not post any grade' do
        grade_passback.process

        expect(Cartridge::BasicOutcomeServiceGradePassbackStrategy)
          .not_to have_received(:new)

        expect(Cartridge::AssignmentAndGradeServiceGradePassbackStrategy)
          .not_to have_received(:new)
      end

      it 'reports an error' do
        grade_passback.process

        expect(VHLMonitor).to have_received(:error).with(
          'Failed to send grade back',
          activity_id: attempt.activity_id,
          errors: ['LTI version is not supported'],
          params: grade_params,
          user_id: student.id
        )
      end
    end
  end
end
