describe Notifier do
  describe '#scheduled_task_status' do
    before do
      @task_name = 'valid_task_name'
      @message = 'valid_task_status_message'
      @msg = Notifier.scheduled_task_status(@task_name, @message).deliver_now
    end

    it 'includes thes task name in the subject' do
      expect(@msg.subject).to eq("Status notification for scheduled task '#{@task_name}'")
    end

    it 'includes the details in the body' do
      expect(@msg.body).to include @message
    end
  end

  describe '#problem_report' do
    let(:activity) { build_stubbed(:activity) }

    let(:content_problem) do
      build_stubbed(:content_problem_report,
                   activity: activity,
                   section: build_stubbed(:section_with_course))
    end

    let(:technical_problem) do
      build_stubbed(:technical_problem_report,
                   activity: activity,
                   section: build_stubbed(:section_with_course))
    end

    before do
      allow(activity).to receive(:list_header) { 'location info' }
    end

    context 'with a content problem report' do
      it 'includes "content problem" in the subject' do
        msg = Notifier.problem_report(content_problem).deliver_now
        expect(msg.subject).to include 'content problem'
      end

      it 'does not include severity level in the body' do
        msg = Notifier.problem_report(content_problem).deliver_now
        expect(msg.body).not_to include 'severity_level'
      end

      it 'includes helpable_item info in the body' do
        msg = Notifier.problem_report(content_problem).deliver_now
        expect(msg.body).to include 'selected_item_type'
        expect(msg.body).to include 'selected_item_id'
      end
    end

    context 'with a technical problem report' do
      it 'includes "technical problem" in the subject' do
        msg = Notifier.problem_report(technical_problem).deliver_now
        expect(msg.subject).to include 'technical problem'
      end

      it 'includes severity level in the body' do
        msg = Notifier.problem_report(technical_problem).deliver_now
        expect(msg.body).to include 'severity_level'
      end

      it 'does not include helpable_item info in the body' do
        msg = Notifier.problem_report(technical_problem).deliver_now
        expect(msg.body).not_to include 'selected_item_type'
        expect(msg.body).not_to include 'selected_item_id'
      end
    end

    it 'includes information about the help request' do
      msg = Notifier.problem_report(content_problem).deliver_now
      body = msg.body
      expect(body).to include content_problem.student_comment
    end

    context 'with a help request that has an invalid user_id' do
      it 'reports no unarchived user found for help_request user_id' do
        allow(content_problem).to receive(:user).and_return(nil)
        expect(Notifier.problem_report(content_problem).deliver_now.body).to include 'No unarchived user found for user_id.'
      end
    end

    context 'with a help request that has an invalid section_id' do
      it 'reports no unarchived section found for help_request section_id' do
        allow(content_problem).to receive(:section).and_return(nil)
        expect(Notifier.problem_report(content_problem).deliver_now.body).to include 'No unarchived section found for section_id.'
      end
    end

    it 'does not fail with a help request that has a section with invalid instructor_id' do
      allow(content_problem.section).to receive(:instructor).and_return(nil)
      expect { Notifier.problem_report(content_problem).deliver_now }.not_to raise_error
    end

    it 'does not fail with a help request that has a section with invalid course_id' do
      allow(content_problem.section).to receive(:course).and_return(nil)
      expect { Notifier.problem_report(content_problem).deliver_now }.not_to raise_error
    end

    it 'does not fail with a help request for a course with invalid owner_id' do
      allow(content_problem.section.course).to receive(:owner).and_return(nil)
      expect { Notifier.problem_report(content_problem).deliver_now }.not_to raise_error
    end

    it 'does not fail with a help request for a course with invalid school_id' do
      allow(content_problem.section.course).to receive(:school).and_return(nil)
      expect { Notifier.problem_report(content_problem).deliver_now }.not_to raise_error
    end

    it 'does not fail with a help request with an invalid activity_id' do
      allow(content_problem).to receive(:activity).and_return(nil)
      expect { Notifier.problem_report(content_problem).deliver_now }.not_to raise_error
    end
  end

  describe "#server_error_report" do
    let(:user) { build_stubbed(:student) }
    let(:server_error_params) do
      { 'user_id'           => user.id,
        'error_id'          => 'rollbar.exception_uuid',
        'http_referer'      => 'HTTP_REFERER',
        'ip_address'        => 'REMOTE_ADDR',
        'user_agent_string' => 'HTTP_USER_AGENT',
        'operating_system'  => 'windows',
        'browser_name'      => 'chrome',
        'browser_version'   => '54.3'
      }
    end
    let(:server_error_report) { ServerErrorReportDispatcher.new(server_error_params) }

    before do
      allow(User).to receive(:find).with(user.id).and_return(user)
    end

    it "shows the error id in the body message" do
      msg = Notifier.server_error_report(server_error_report).deliver_now
      expect(msg.from).to include 'no_reply_problem_reports@vistahigherlearning.com'
      expect(msg.subject).to include 'A rollbar issue has been reported by a user'
      expect(msg.body).to include server_error_report.error_id
      expect(msg.body).to include server_error_report.http_referer
      expect(msg.body).to include server_error_report.ip_address
      expect(msg.body).to include server_error_report.user_comment
    end
  end
end
