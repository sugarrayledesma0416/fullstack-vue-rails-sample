describe Cartridge::BasicOutcomeServiceGradePassbackStrategy do
  let(:school) { create(:school) }
  let(:course) { create(:course) }
  let(:section) { create(:section) }
  let(:student) { create(:student) }
  let(:activity) { create(:activity) }
  let(:attempt) { create(:attempt, section: section, user: student, activity: activity) }
  let(:consumer_cartridge) { create(:cartridge_consumer, school: school) }
  let(:strategy) do
    described_class.new(student, attempt, consumer_guid: consumer_cartridge.guid)
  end
  let(:lti_tool_provider) do
    instance_double(
      IMS::LTI::ToolProvider,
      'outcome_service?' => true,
      'post_replace_result!' => lti_response
    )
  end
  let(:lti_response) do
    instance_double(IMS::LTI::OutcomeResponse, 'success?' => true)
  end
  let(:cartidge_score_destination) do
    create(
      :cartridge_score_destination,
      user: student,
      section_id: section.id,
      activity_id: activity.id
    )
  end
  let(:course_context_detail) do
    create(
      :cartridge_course_context_detail,
      course: course,
      section: section,
      school: school
    )
  end
  let(:resource_link) do
    create(
      :cartridge_resource_link,
      resource_id: activity.id,
      resource_type: :activity
    )
  end
  let!(:lti_params) do
    {
      activity_id: activity.id,
      lis_outcome_service_url: course_context_detail.lis_outcome_service_url,
      lis_result_sourcedid: cartidge_score_destination.lis_result_sourcedid,
      resource_link_id: resource_link.resource_link_id,
      user_id: student.id
    }
  end

  before do
    allow(IMS::LTI::ToolProvider).to receive(:new).and_return(lti_tool_provider)
    allow(VHLMonitor).to receive(:error)
  end

  describe '#post_grade' do
    context 'when the consumer_guid is blank,' do
      it 'logs the error to the VHLMonitor' do
        params = { consumer_guid: nil }
        strategy = described_class.new(student, attempt, params)

        strategy.post_grade

        expect(VHLMonitor).to have_received(:error).with(
          described_class::GRADE_PASSBACK_FAILED_MSG,
          activity_id: activity.id,
          errors: ['consumer_guid is blank'],
          params: params,
          resource_link_id: resource_link.resource_link_id,
          user_id: student.id
        )
      end
    end

    it 'initializes an lti provider with the given cartidge consumer' do
      strategy.post_grade

      expect(IMS::LTI::ToolProvider).to have_received(:new).with(
        consumer_cartridge.key,
        consumer_cartridge.secret,
        'lis_result_sourcedid' => cartidge_score_destination.lis_result_sourcedid,
        'lis_outcome_service_url' => course_context_detail.lis_outcome_service_url,
        'user_id' => student.id
      )
    end

    context 'when the LTI service does not expect a response' do
      before do
        allow(lti_tool_provider).to receive(:outcome_service?).and_return(false)
      end

      it 'does not send the grade' do
        strategy.post_grade
        expect(lti_tool_provider).not_to have_received('post_replace_result!')
      end

      it 'does not log any error' do
        strategy.post_grade

        expect(VHLMonitor).not_to have_received(:error)
      end
    end

    context 'when the LTI service expects a response' do
      context 'when successful' do
        context 'when the activity is submittable,' do
          let(:activity) { create(:activity, submittable: true) }

          it 'post a result from the attempt to the lms' do
            score = double(
              GradebookEngine::CurrentScoreAction,
              points_earned: 12.0,
              points_possible: 20.0,
              pending: false
            )
            allow(GradebookEngine::GradebookAPI)
              .to receive(:find_score)
              .and_return(score)

            strategy.post_grade

            expect(lti_tool_provider)
              .to have_received('post_replace_result!')
              .with(score.points_earned / score.points_possible)
          end
        end

        context 'when the activity is not submittable,' do
          let(:activity) { create(:activity, submittable: false) }

          it 'post a result of 1.0 to the lms' do
            strategy.post_grade

            expect(lti_tool_provider).to have_received('post_replace_result!').with(1.0)
          end
        end
      end

      context 'when an error occurs' do
        let(:activity) { create(:activity, submittable: false) }
        let(:expected_response_code) { 500 }
        let(:expected_response_body) { 'Something when wrong' }

        it 'logs the error to the VHLMonitor if the response was not successful' do
          allow(lti_response).to receive(:success?).and_return(false)
          allow(lti_response).to receive(:response_code).and_return(
            expected_response_code
          )
          allow(lti_response).to receive(:post_response).and_return(
            OpenStruct.new(body: expected_response_body)
          )

          strategy.post_grade

          expect(VHLMonitor).to have_received(:error).with(
            described_class::GRADE_PASSBACK_FAILED_MSG,
            lti_params: lti_params,
            response_code: expected_response_code,
            response_body: expected_response_body
          )
        end

        it 'logs the error to the VHLMonitor if it throws an exception' do
          expected_exception_message = 'An exception occurred.'
          allow(lti_tool_provider).to receive(:post_replace_result!).and_raise(
            expected_exception_message
          )

          strategy.post_grade

          expect(VHLMonitor).to have_received(:error).with(
            described_class::GRADE_PASSBACK_FAILED_MSG,
            lti_params: lti_params,
            exception_message: expected_exception_message
          )
        end
      end
    end
  end
end
