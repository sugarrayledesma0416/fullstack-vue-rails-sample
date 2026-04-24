describe HelpRequestSubmitter do
  let(:program) { create(:program_with_lessons_and_resource_units) }
  let(:lessons) { program.lessons }
  let(:course) { create(:course, program:, allows_help_requests: true) }
  let(:section) { create(:section, course:) }
  let(:activity) do
    create(:activity, cms_activity_id: 10, cms_revision_id: 20, lesson: lessons.first)
  end
  let(:help_request) do
    build_stubbed(
      :help_request,
      user_id: user.id,
      activity_id: activity.id,
      program_id: program.id
    )
  end
  let(:review_request) do
    build_stubbed(
      :review_request,
      user_id: user.id,
      activity_id: activity.id,
      program_id: program.id
    )
  end
  let(:technical_problem_report) do
    build_stubbed(
      :technical_problem_report,
      user_id: user.id,
      activity_id: activity.id,
      program_id: program.id
    )
  end
  let(:content_problem_report) do
    build_stubbed(
      :content_problem_report,
      user_id: user.id,
      activity_id: activity.id,
      program_id: program.id
    )
  end
  let(:agent_string) do
    'Mozilla/5.0 (Windows; U; Windows NT 6.0; en-us) AppleWebKit/531.9 ' \
      '(KHTML, like Gecko) Version/4.0.3 Safari/531.9'
  end
  let(:request) do
    double('request', env: { 'REMOTE_ADDR' => '0.0.0.0', 'HTTP_USER_AGENT' => agent_string })
  end
  let(:help_request_data) do
    {
      activity_id: activity.id,
      activity_state: 'try',
      cms_activity_id: activity.cms_activity_id,
      cms_revision_id: activity.cms_revision_id,
      http_referer: 'referer_url.dom',
      program_id: program.id,
      request_type: 'request_help',
      section_id: section.id
    }
  end
  let(:score_review_data) do
    {
      activity_id: activity.id,
      activity_state: 'complete',
      cms_activity_id: activity.cms_activity_id,
      cms_revision_id: activity.cms_revision_id,
      http_referer: 'referer_url.dom',
      program_id: program.id,
      request_type: 'request_review',
      section_id: section.id
    }
  end
  let(:technical_problem_data) do
    {
      activity_id: activity.id,
      activity_state: 'try',
      cms_activity_id: activity.cms_activity_id,
      cms_revision_id: activity.cms_revision_id,
      http_referer: 'referer_url.dom',
      program_id: program.id,
      request_type: 'technical_problem_report',
      section_id: section.id
    }
  end
  let(:content_problem_data) do
    {
      activity_id: activity.id,
      activity_state: 'try',
      cms_activity_id: activity.cms_activity_id,
      cms_revision_id: activity.cms_revision_id,
      http_referer: 'referer_url.dom',
      program_id: program.id,
      request_type: 'content_problem_report',
      section_id: section.id
    }
  end
  let(:activity_params) { 'question_01=right%20answer&start_time=some_time' }
  let(:default_params) do
    {
      flash_version: '11.0.0.1',
      activity_form_contents: activity_params,
      student_comment: 'this is a help request'
    }
  end
  let(:activity_saver) { instance_double(ActivityWorkSaver, save: true) }
  let(:notifier) { instance_double(Notifier) }
  let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }
  let(:filter_params) { default_params.merge(help_request_data) }
  let(:submitter) { described_class.new(user, filter_params, request.env) }

  before do
    allow_any_instance_of(Activity).to receive(:result_labels).and_return(['question_01'])
    allow(ActivityWorkSaver).to receive(:new).and_return(activity_saver)
  end

  shared_examples 'does not create an help request and returns a generic error message' do
    it 'does not create an help request' do
      submitter.submit

      expect(HelpRequest).not_to have_received(:create)
    end

    it 'sets results with an error message' do
      submitter.submit

      expect(submitter.result).to eq(
        errors: ['Error submitting the help request.']
      )
    end

    it 'sets status attribute to unprocessable_entity' do
      submitter.submit

      expect(submitter.status).to eq(:unprocessable_entity)
    end

    it 'does not send problem support notification if the request is a problem report' do
      allow(help_request).to receive(:problem_report?).and_return(true)

      submitter.submit

      expect(Notifier).not_to have_received(:problem_report).with(help_request)
    end
  end

  describe '#submit' do
    before do
      allow(HelpRequest).to receive(:create).and_return(help_request)
      allow(Notifier).to receive(:problem_report).and_return(message_delivery)
      allow(message_delivery).to receive(:deliver_now)
    end

    context 'when the user submitting the help request is a student,' do
      let(:user) { create(:student) }
      let!(:attempt) do
        create(
          :attempt_opened,
          section_id: section.id,
          user_id: user.id,
          activity_id: activity.id
        )
      end

      context 'when the user is enrolled in the specified course,' do
        before do
          create(:enrollment, user:, section:)
        end

        it 'creates a help request using the formatted params' do
          submitter.submit

          expect(HelpRequest).to have_received(:create).with(
            activity_id: activity.id,
            activity_state: 'try',
            browser_name: 'Safari',
            browser_version: '4.0.3',
            cms_activity_id: activity.cms_activity_id,
            cms_revision_id: activity.cms_revision_id,
            flash_version: '11.0.0.1',
            http_referer: 'referer_url.dom',
            ip_address: request.env['REMOTE_ADDR'],
            operating_system: 'Windows Vista',
            program_id: program.id,
            request_type: 'request_help',
            section_id: section.id,
            student_comment: 'this is a help request',
            user_agent_string: request.env['HTTP_USER_AGENT'],
            user_id: user.id
          )
        end

        it "assigns help request's attributes to results" do
          submitter.submit

          expect(submitter.result).to eq(help_request.attributes)
        end

        it 'sets status attribute to success' do
          submitter.submit

          expect(submitter.status).to eq(:ok)
        end

        it 'sends a problem support notification if the request is a problem report' do
          allow(help_request).to receive(:problem_report?).and_return(true)

          submitter.submit

          expect(Notifier).to have_received(:problem_report).with(help_request)
          expect(message_delivery).to have_received(:deliver_now)
        end

        it 'does not send problem support notification if the request is not a problem report' do
          allow(help_request).to receive(:problem_report?).and_return(false)

          submitter.submit

          expect(Notifier).not_to have_received(:problem_report)
        end

        it "does not save user's current work when attempt is completed" do
          attempt.update!(status_code: AttemptStatus::CODE_COMPLETED)

          submitter.submit

          expect(ActivityWorkSaver).not_to have_received(:new)
        end

        it "does not save user's current work when the attempt is submitted" do
          attempt.update!(status_code: AttemptStatus::CODE_SUBMITTED)

          submitter.submit

          expect(ActivityWorkSaver).not_to have_received(:new)
        end

        it "does not save user's current work when the activity is not submittable" do
          activity.update!(submittable: false)

          submitter.submit

          expect(ActivityWorkSaver).not_to have_received(:new)
        end

        it "does not save user's current work when attempt's activity is virtual chat" do
          activity.update!(activity_type: 'virtual_chat')

          submitter.submit

          expect(ActivityWorkSaver).not_to have_received(:new)
        end

        it "does not save user's current work when attempt's activity is partner chat" do
          activity.update!(activity_type: 'partner_chat')

          submitter.submit

          expect(ActivityWorkSaver).not_to have_received(:new)
        end

        it "does not save user's current work when attempt's activity is solo video recording" do
          activity.update!(activity_type: 'solo_video_recording')

          submitter.submit

          expect(ActivityWorkSaver).not_to have_received(:new)
        end

        it "does not save user's current work when attempt's activity is group chat" do
          activity.update!(activity_type: 'group_chat')

          submitter.submit

          expect(ActivityWorkSaver).not_to have_received(:new)
        end

        context 'when there are no responses to save' do
          let(:activity_params) { 'question_01=&start_time=some_time' }

          it "does not save user's current work" do
            submitter.submit

            expect(ActivityWorkSaver).not_to have_received(:new)
          end
        end

        context "when activity_params has keys, but they don't overlap with any of the result labels" do
          let(:activity_params) { 'start_time=some_time' }

          it "does not save user's current work" do
            submitter.submit

            expect(ActivityWorkSaver).not_to have_received(:new)
          end
        end

        context 'when activity_params has keys and they overlap with at least one of the result labels' do
          let(:activity_params) { "question_01=#{question_01_response}&start_time=some_time" }

          context 'when there are no responses to save' do
            let(:question_01_response) { '' }

            it "does not save user's current work" do
              submitter.submit

              expect(ActivityWorkSaver).not_to have_received(:new)
            end
          end

          context 'when there are responses to save' do
            let(:question_01_response) { 'some cool response' }

            it "does not save user's current work" do
              submitter.submit

              expect(ActivityWorkSaver).to have_received(:new).with(
                activity,
                attempt,
                Rack::Utils.parse_query(activity_params),
                request.env
              )
              expect(activity_saver).to have_received(:save)
            end
          end
        end

        it "does not save user's current work when the activity has been completed" do
          attempt.update!(status_code: AttemptStatus::CODE_COMPLETED)

          submitter.submit

          expect(ActivityWorkSaver).not_to have_received(:new)
        end


        it "does not save user's current work when the activity has been submitted'" do
          attempt.update!(status_code: AttemptStatus::CODE_SUBMITTED)

          submitter.submit

          expect(ActivityWorkSaver).not_to have_received(:new)
        end

        context 'when help request is created with errors' do
          before do
            help_request.errors.add(:base, 'some error')
          end

          it 'sets results with an error message' do
            submitter.submit

            expect(submitter.result).to eq(errors: ['some error'])
          end

          it 'sets status attribute to unprocessable_entity' do
            submitter.submit

            expect(submitter.status).to eq(:unprocessable_entity)
          end

          it 'does not send problem support notification if the request is a problem report' do
            allow(help_request).to receive(:problem_report?).and_return(true)

            submitter.submit

            expect(Notifier).not_to have_received(:problem_report).with(help_request)
          end
        end

        context 'when submitting from section zero,' do
          let(:filter_params) { super().merge(section_id: Section.section_zero.id) }

          it 'creates a help request using the formatted params' do
            submitter.submit

            expect(HelpRequest).to have_received(:create).with(
              activity_id: activity.id,
              activity_state: 'try',
              browser_name: 'Safari',
              browser_version: '4.0.3',
              cms_activity_id: activity.cms_activity_id,
              cms_revision_id: activity.cms_revision_id,
              flash_version: '11.0.0.1',
              http_referer: 'referer_url.dom',
              ip_address: request.env['REMOTE_ADDR'],
              operating_system: 'Windows Vista',
              program_id: program.id,
              request_type: 'request_help',
              section_id: Section.section_zero.id,
              student_comment: 'this is a help request',
              user_agent_string: request.env['HTTP_USER_AGENT'],
              user_id: user.id
            )
          end

          context 'when the specified activity with the specified CMS activity id does not exist' do
            let(:filter_params) do
              super().merge(cms_activity_id: activity.cms_activity_id + 1)
            end

            include_examples 'does not create an help request and returns a generic error message'
          end

          context 'when the specified activity with the specified CMS activity id does not exist' do
            let(:filter_params) do
              super().merge(cms_revision_id: activity.cms_revision_id + 1)
            end

            include_examples 'does not create an help request and returns a generic error message'
          end
        end

        context 'when the specified section does not exist,' do
          let(:filter_params) { super().merge(section_id: 'non-existent') }

          include_examples 'does not create an help request and returns a generic error message'
        end

        context 'when the specified course is closed,' do
          let(:course) { create(:closed_course, program:, allows_help_requests: true) }

          include_examples 'does not create an help request and returns a generic error message'
        end

        context 'when the specified course does not allow help requests,' do
          let(:course) { create(:course, program:, allows_help_requests: false) }

          include_examples 'does not create an help request and returns a generic error message'
        end

        context 'when the specified course does not allow help requests ' \
        'or score review requests,' do
          let(:course) do
            create(:course, program:, allows_help_requests: false, allows_review_requests: false)
          end

          context 'when request type is technical problem report,' do
            before do
              allow(HelpRequest).to receive(:create).and_return(technical_problem_report)
            end

            let(:default_params) do
              {
                flash_version: '11.0.0.1',
                activity_form_contents: activity_params,
                student_comment: 'this is a technical problem report'
              }
            end
            let(:filter_params) { default_params.merge(technical_problem_data) }

            it 'creates a technical problem report using the formatted params' do
              submitter.submit

              expect(HelpRequest).to have_received(:create).with(
                activity_id: activity.id,
                activity_state: 'try',
                browser_name: 'Safari',
                browser_version: '4.0.3',
                cms_activity_id: activity.cms_activity_id,
                cms_revision_id: activity.cms_revision_id,
                flash_version: '11.0.0.1',
                http_referer: 'referer_url.dom',
                ip_address: request.env['REMOTE_ADDR'],
                operating_system: 'Windows Vista',
                program_id: program.id,
                request_type: 'technical_problem_report',
                section_id: section.id,
                student_comment: 'this is a technical problem report',
                user_agent_string: request.env['HTTP_USER_AGENT'],
                user_id: user.id
              )
            end
          end

          context 'when request type is content problem report,' do
            before do
              allow(HelpRequest).to receive(:create).and_return(content_problem_report)
            end

            let(:default_params) do
              {
                flash_version: '11.0.0.1',
                activity_form_contents: activity_params,
                student_comment: 'this is a content problem report'
              }
            end
            let(:filter_params) { default_params.merge(content_problem_data) }

            it 'creates a content problem report using the formatted params' do
              submitter.submit

              expect(HelpRequest).to have_received(:create).with(
                activity_id: activity.id,
                activity_state: 'try',
                browser_name: 'Safari',
                browser_version: '4.0.3',
                cms_activity_id: activity.cms_activity_id,
                cms_revision_id: activity.cms_revision_id,
                flash_version: '11.0.0.1',
                http_referer: 'referer_url.dom',
                ip_address: request.env['REMOTE_ADDR'],
                operating_system: 'Windows Vista',
                program_id: program.id,
                request_type: 'content_problem_report',
                section_id: section.id,
                student_comment: 'this is a content problem report',
                user_agent_string: request.env['HTTP_USER_AGENT'],
                user_id: user.id
              )
            end
          end
        end

        context 'when request type is score review request,' do
          context 'when the specified course does not allow score review requests,' do
            let(:course) do
              create(:course, program:, allows_help_requests: true, allows_review_requests: false)
            end
            let(:default_params) do
              {
                flash_version: '11.0.0.1',
                activity_form_contents: activity_params,
                student_comment: 'this is a score review request'
              }
            end
            let(:filter_params) { default_params.merge(score_review_data) }

            it 'does not create a score review request' do
              submitter.submit

              expect(HelpRequest).not_to have_received(:create)
            end
          end

          context 'when the specified course allows score review requests,' do
            before do
              allow(HelpRequest).to receive(:create).and_return(review_request)
            end

            let(:course) do
              create(:course, program:, allows_help_requests: false, allows_review_requests: true)
            end
            let(:default_params) do
              {
                flash_version: '11.0.0.1',
                activity_form_contents: activity_params,
                student_comment: 'this is a score review request'
              }
            end
            let(:filter_params) { default_params.merge(score_review_data) }

            it 'creates a score review request using the formatted params' do
              submitter.submit

              expect(HelpRequest).to have_received(:create).with(
                activity_id: activity.id,
                activity_state: 'complete',
                browser_name: 'Safari',
                browser_version: '4.0.3',
                cms_activity_id: activity.cms_activity_id,
                cms_revision_id: activity.cms_revision_id,
                flash_version: '11.0.0.1',
                http_referer: 'referer_url.dom',
                ip_address: request.env['REMOTE_ADDR'],
                operating_system: 'Windows Vista',
                program_id: program.id,
                request_type: 'request_review',
                section_id: section.id,
                student_comment: 'this is a score review request',
                user_agent_string: request.env['HTTP_USER_AGENT'],
                user_id: user.id
              )
            end
          end
        end

        context "when the specified activity does not belong to the course's program" do
          let(:activity) { create(:activity, cms_activity_id: 10, cms_revision_id: 20) }

          include_examples 'does not create an help request and returns a generic error message'
        end

        context 'when the specified activity with the specified CMS activity id does not exist' do
          let(:filter_params) do
            super().merge(cms_activity_id: activity.cms_activity_id + 1)
          end

          include_examples 'does not create an help request and returns a generic error message'
        end

        context 'when the specified activity with the specified CMS activity id does not exist' do
          let(:filter_params) do
            super().merge(cms_revision_id: activity.cms_revision_id + 1)
          end

          include_examples 'does not create an help request and returns a generic error message'
        end
      end

      context 'when the student is not enrolled in the specified course,' do
        include_examples 'does not create an help request and returns a generic error message'
      end

      context 'when the specified course does not exist,' do
        let(:filter_params) { super().merge(section_id: 'non-existent') }

        include_examples 'does not create an help request and returns a generic error message'
      end
    end

    context 'when the user submitting the help request is an instructor,' do
      let(:user) { create(:instructor) }

      context 'when the instructor is an instructor in the specified course,' do
        before do
          create(:section_instructor, section:, user_id: user.id)
        end

        it 'creates a help request using the formatted params' do
          submitter.submit

          expect(HelpRequest).to have_received(:create).with(
            activity_id: activity.id,
            activity_state: 'try',
            browser_name: 'Safari',
            browser_version: '4.0.3',
            cms_activity_id: activity.cms_activity_id,
            cms_revision_id: activity.cms_revision_id,
            flash_version: '11.0.0.1',
            http_referer: 'referer_url.dom',
            ip_address: request.env['REMOTE_ADDR'],
            operating_system: 'Windows Vista',
            program_id: program.id,
            request_type: 'request_help',
            section_id: section.id,
            student_comment: 'this is a help request',
            user_agent_string: request.env['HTTP_USER_AGENT'],
            user_id: user.id
          )
        end

        it "assigns help request's attributes to results" do
          submitter.submit

          expect(submitter.result).to eq(help_request.attributes)
        end

        it 'sets status attribute to success' do
          submitter.submit

          expect(submitter.status).to eq(:ok)
        end
      end

      context 'when submitting from section zero,' do
        let(:filter_params) { super().merge(section_id: Section.section_zero.id) }

        it 'creates a help request using the formatted params' do
          submitter.submit

          expect(HelpRequest).to have_received(:create).with(
            activity_id: activity.id,
            activity_state: 'try',
            browser_name: 'Safari',
            browser_version: '4.0.3',
            cms_activity_id: activity.cms_activity_id,
            cms_revision_id: activity.cms_revision_id,
            flash_version: '11.0.0.1',
            http_referer: 'referer_url.dom',
            ip_address: request.env['REMOTE_ADDR'],
            operating_system: 'Windows Vista',
            program_id: program.id,
            request_type: 'request_help',
            section_id: Section.section_zero.id,
            student_comment: 'this is a help request',
            user_agent_string: request.env['HTTP_USER_AGENT'],
            user_id: user.id
          )
        end
      end

      context 'when the instructor is not an instructor in the specified course,' do
        include_examples 'does not create an help request and returns a generic error message'
      end

      context 'when the specified course does not exist,' do
        let(:filter_params) { super().merge(section_id: 'non-existent') }

        include_examples 'does not create an help request and returns a generic error message'
      end
    end
  end
end
