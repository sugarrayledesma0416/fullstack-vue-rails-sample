describe ActivityAssignmentsController do
  describe '#update' do
    let(:assignment_processor) { double('assignment processor') }
    before do
      @instructor = build_stubbed(:instructor)
      fake_login(@instructor)
      populate_instructor_program_and_focus
      @default_params = {
        selected_activities: '',
        update_type: 'assign',
        activity_assignment: {
          'due_date' => Date.today.to_s
        },
        program_id: 0
      }
    end

    def do_request(params = {})
      put :update, params: @default_params.merge(params), xhr: true
    end

    context 'for all cases,' do
      before do
        allow(assignment_processor).to receive(:process)
        allow(assignment_processor).to receive(:update_session_due_date_and_category)
        allow(assignment_processor).to receive(:success).and_return([])
        allow(assignment_processor).to receive(:failure).and_return([])
        allow(AssignmentUpdateProcessor).to receive(:new).and_return(assignment_processor)
      end
      it_should_behave_like 'an action that requires a logged in instructor'
    end

    context 'when update fails,' do
      before do
        allow(assignment_processor).to receive(:process)
        allow(assignment_processor).to receive(:update_session_due_date_and_category)
        allow(assignment_processor).to receive(:success).and_return([])
        allow(assignment_processor).to receive(:failure).and_return([])
        allow(controller).to receive(:error_messages_for_modal).and_return('error')
        allow(AssignmentUpdateProcessor).to receive(:new).and_return(assignment_processor)
      end

      it 'should respond with error message and status 500 ' do
        do_request({})
        expect(response.status).to eq(422)
      end
    end
  end

  describe '#detect_institution_admin_context' do
    before do
      @instructor = build_stubbed(:instructor)
      fake_login(@instructor)
      populate_instructor_program_and_focus
    end

    context 'when referrer includes /institution_admin/' do
      it 'sets @institution_admin_context to true' do
        request.env['HTTP_REFERER'] = 'https://example.com/institution_admin/toc_templates/123'
        controller.send(:detect_institution_admin_context)
        expect(controller.instance_variable_get(:@institution_admin_context)).to be true
      end
    end

    context 'when referrer does not include /institution_admin/' do
      it 'sets @institution_admin_context to false' do
        request.env['HTTP_REFERER'] = 'https://example.com/instructor/dashboard'
        controller.send(:detect_institution_admin_context)
        expect(controller.instance_variable_get(:@institution_admin_context)).to be false
      end
    end

    context 'when there is no referrer' do
      it 'sets @institution_admin_context to false' do
        request.env['HTTP_REFERER'] = nil
        controller.send(:detect_institution_admin_context)
        expect(controller.instance_variable_get(:@institution_admin_context)).to be false
      end
    end

    context 'with different institution_admin URLs' do
      it 'detects institution_admin in various paths' do
        [
          'https://example.com/institution_admin/courses',
          'https://example.com/institution_admin/dashboard',
          'http://localhost:3000/institution_admin/toc_templates/456',
          'https://vhlcentral.com/institution_admin/sections/789'
        ].each do |url|
          request.env['HTTP_REFERER'] = url
          controller.send(:detect_institution_admin_context)
          expect(controller.instance_variable_get(:@institution_admin_context)).to be true
        end
      end
    end

    context 'with non-institution_admin URLs' do
      it 'does not detect institution_admin in regular paths' do
        [
          'https://example.com/instructor/dashboard',
          'https://example.com/courses/123',
          'http://localhost:3000/gradebook/456',
          'https://vhlcentral.com/students/789',
          'https://example.com/some_other_admin/page'
        ].each do |url|
          request.env['HTTP_REFERER'] = url
          controller.send(:detect_institution_admin_context)
          expect(controller.instance_variable_get(:@institution_admin_context)).to be false
        end
      end
    end

    context 'edge cases' do
      it 'handles empty string referrer' do
        request.env['HTTP_REFERER'] = ''
        controller.send(:detect_institution_admin_context)
        expect(controller.instance_variable_get(:@institution_admin_context)).to be false
      end

      it 'handles referrer with institution_admin as substring but not path' do
        request.env['HTTP_REFERER'] = 'https://institution_admin.example.com/regular/page'
        controller.send(:detect_institution_admin_context)
        expect(controller.instance_variable_get(:@institution_admin_context)).to be false
      end
    end
  end
end
