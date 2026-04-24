describe Cartridge::AssignmentAndGradeServiceGradePassbackStrategy do
  let(:school) { create(:school) }
  let(:course) { create(:course) }
  let(:section) { create(:section) }
  let(:student) { create(:student, schools: [school]) }
  let(:activity) { create(:activity) }
  let(:attempt) { create(:attempt, section:, user: student, activity:) }
  let(:strategy) do
    described_class.new(student, attempt, platform_guid: platform.guid)
  end
  let!(:course_context_detail) do
    create(
      :cartridge_course_context_detail,
      course:,
      section:,
      school:
    )
  end
  let!(:resource_link) do
    create(
      :cartridge_resource_link,
      resource_id: activity.id,
      resource_type: :activity
    )
  end
  let(:platform) do
    GradebookEngine::Lti::Platform.new(
      guid: SecureRandom.uuid,
      lms_type: 'Canvas'
    )
  end
  let(:line_item) do
    instance_double(GradebookEngine::Lti::LineItem, sync: true, post_grade: true)
  end
  let(:score) do
    double(GradebookEngine::CurrentScoreAction, pending: false)
  end
  let(:external_user_id) { SecureRandom.uuid }
  let(:error_collector) do
    instance_double(
      GradebookEngine::Lti::ErrorCollector,
      errors: {},
      has_errors?: false,
      has_warnings?: false,
      warnings: {}
    )
  end
  let(:errors) do
    {
      {
        category: :some_category,
        context: 'Action 1',
        message: 'error message'
      } => 1,
      {
        category: :some_category,
        context: 'Action 2',
        message: 'error message'
      } => 2
    }
  end
  let(:warnings) do
    {
      {
        category: :some_category,
        context: 'Action 1',
        message: 'warning message'
      } => 1,
      {
        category: :some_category,
        context: 'Action 2',
        message: 'warning message'
      } => 2
    }
  end

  before do
    allow(VHLMonitor).to receive(:error)

    create(
      :cartridge_student_user_link,
      school:,
      user: student,
      external_user_id:
    )
    allow(GradebookEngine::Lti::LineItem)
      .to receive(:new)
      .and_return(line_item)
    allow(GradebookEngine::Lti::ErrorCollector).to receive(:new)
      .and_return(error_collector)
    allow(GradebookEngine::GradebookAPI).to receive(:find_score)
      .and_return(score)
    allow(GradebookEngine::Lti::Platform).to receive(:find_by)
      .with(guid: platform.guid).and_return(platform)
  end

  describe '#post_grade' do
    context 'when the platform_guid is blank,' do
      it 'logs the error to the VHLMonitor' do
        params = { platform_guid: nil }
        strategy = described_class.new(student, attempt, params)

        strategy.post_grade

        expect(VHLMonitor).to have_received(:error).with(
          described_class::GRADE_PASSBACK_FAILED_MSG,
          activity_id: activity.id,
          errors: ['platform_guid is blank'],
          params:,
          resource_link_id: resource_link.resource_link_id,
          user_id: student.id
        )
      end
    end

    context 'when the LTI service does not expect a response (no line item destination)' do
      it 'does not send any grade to the LMS' do
        strategy.post_grade

        expect(GradebookEngine::Lti::LineItem).not_to have_received(:new)
      end

      it 'does not log any error' do
        strategy.post_grade

        expect(VHLMonitor).not_to have_received(:error)
      end
    end

    context 'when the LTI service expects a response' do
      let(:line_item_url) do
        "https://lms.example.org/api/lti/courses/#{SecureRandom.uuid}/line_item/#{rand(1..99)}"
      end
      let(:token) { instance_double(GradebookEngine::Lti::AuthToken) }

      before do
        create(
          :cartridge_line_item_destination,
          user: student,
          section:,
          activity:,
          line_item_url:
        )
        allow(GradebookEngine::Lti::AuthToken)
          .to receive(:new)
          .with(platform:)
          .and_return(token)
      end

      shared_examples 'handles access token error' do
        context 'when the line item raises a token error,' do
          let(:auth_token_error) { GradebookEngine::Lti::AuthTokenError.new(token) }

          before do
            allow(line_item).to receive(:sync).and_raise(auth_token_error)
            allow(error_collector).to receive(:has_errors?).and_return(true)
            allow(error_collector).to receive(:errors).and_return(errors)
          end

          it 'logs the error to the VHLMonitor' do
            strategy.post_grade

            expect(VHLMonitor).to have_received(:error).with(
              described_class::GRADE_PASSBACK_FAILED_MSG,
              activity_id: activity.id,
              errors:,
              params: { platform_guid: platform.guid },
              resource_link_id: resource_link.resource_link_id,
              user_id: student.id
            )
          end
        end
      end

      shared_examples 'handles unrecoverable sync error' do
        context 'when the line item raises an unrecoverable sync error,' do
          let(:unrecoverable_sync_error) { GradebookEngine::Lti::UnrecoverableSyncError.new }

          before do
            allow(line_item).to receive(:sync).and_raise(unrecoverable_sync_error)
            allow(error_collector).to receive(:has_errors?).and_return(true)
            allow(error_collector).to receive(:errors).and_return(errors)
          end

          it 'logs the error to the VHLMonitor' do
            strategy.post_grade

            expect(VHLMonitor).to have_received(:error).with(
              described_class::GRADE_PASSBACK_FAILED_MSG,
              activity_id: activity.id,
              errors:,
              params: { platform_guid: platform.guid },
              resource_link_id: resource_link.resource_link_id,
              user_id: student.id
            )
          end
        end
      end

      shared_examples 'logs errors and warnings from the error collector' do
        context 'when the error collector contains errors,' do
          before do
            allow(error_collector).to receive(:has_errors?).and_return(true)
            allow(error_collector).to receive(:errors).and_return(errors)
          end

          it 'logs the error to the VHLMonitor' do
            strategy.post_grade

            expect(VHLMonitor).to have_received(:error).with(
              described_class::GRADE_PASSBACK_FAILED_MSG,
              activity_id: activity.id,
              errors:,
              params: { platform_guid: platform.guid },
              resource_link_id: resource_link.resource_link_id,
              user_id: student.id
            )
          end
        end

        context 'when the error collector contains warnings,' do
          before do
            allow(error_collector).to receive(:has_warnings?).and_return(true)
            allow(error_collector).to receive(:warnings).and_return(warnings)
          end

          it 'logs the warnings as errors to the VHLMonitor' do
            strategy.post_grade

            expect(VHLMonitor).to have_received(:error).with(
              described_class::GRADE_PASSBACK_FAILED_MSG,
              activity_id: activity.id,
              errors: warnings,
              params: { platform_guid: platform.guid },
              resource_link_id: resource_link.resource_link_id,
              user_id: student.id
            )
          end
        end
      end

      context 'when the activity is submittable,' do
        let(:activity) { create(:activity, submittable: true) }
        let(:score) do
          double(
            GradebookEngine::CurrentScoreAction,
            points_earned: 12.0,
            points_possible: 20.0,
            pending: false,
            submitted_at: 2.days.ago
          )
        end

        before do
          allow(GradebookEngine::GradebookAPI)
            .to receive(:find_score)
            .and_return(score)
        end

        it 'post a result from the attempt to the lms' do
          strategy.post_grade

          expect(line_item).to have_received(:post_grade).with(
            external_user_id,
            an_object_having_attributes(
              submitted_at: score.submitted_at,
              score: 0.6,
              points_earned_for_display: score.points_earned,
              points_possible_for_display: score.points_possible,
              level: 'activity'
            )
          )
        end

        include_examples 'handles access token error'
        include_examples 'handles unrecoverable sync error'
        include_examples 'logs errors and warnings from the error collector'
      end

      context 'when the activity is not submittable,' do
        let(:activity) { create(:activity, submittable: false) }

        before do
          allow(GradebookEngine::Lti::ContextLink).to receive(:new)
        end

        it 'post a result of 1.0 to the lms' do
          strategy.post_grade

          expect(line_item).to have_received(:post_grade).with(
            external_user_id,
            an_object_having_attributes(
              submitted_at: nil,
              score: 1.0,
              points_earned_for_display: 1.0,
              points_possible_for_display: 1.0,
              level: 'activity'
            )
          )
        end

        include_examples 'handles access token error'
        include_examples 'handles unrecoverable sync error'
        include_examples 'logs errors and warnings from the error collector'

        # TODO: This is a temporary test to ensure that the ContextLink
        # is created with the correct details please update with STATS_PROXY pattern.
        it 'creates a ContextLink with the correct platform, context, and section details' do
          Timecop.freeze(Time.current) do
            strategy.post_grade

            expect(GradebookEngine::Lti::ContextLink).to have_received(:new)
              .with(
                lti_platform: platform,
                context_id: course_context_detail.lms_context_id,
                section: course_context_detail.section,
                guid: "common_cartridge_context_details_id: #{course_context_detail.id}",
                context_title: course_context_detail.section.course.name,
                context_label: course_context_detail.section.name
              )
          end
        end
      end
    end
  end
end
