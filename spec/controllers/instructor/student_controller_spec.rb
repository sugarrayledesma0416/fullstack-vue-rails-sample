describe Instructor::StudentController, core: true do
  describe '#search' do
    before do
      @instructor = build_stubbed(:instructor)
      allow(@instructor).to receive(:setting)
      allow(@instructor).to receive(:has_current_access_to?).and_return(true)
      fake_login(@instructor)
      @program = build_stubbed(:program)
      course = build_stubbed(:course)
      school = build_stubbed(:school)
      allow(course).to receive(:school).and_return(school)

      @section = build_stubbed(:section)
      allow(@section).to receive(:course).and_return(course)

      allow(Program).to receive(:find).and_return(@program)
      allow(Section).to receive(:find).and_return(@section)
    end

    it 'assign page header' do
      get :search, params: { program_id: @program.id, section_id: @section.id }
      expect(assigns(:page_header)).to have_text(/student/)
      expect(assigns(:page_header)).to have_text(/search/)
    end

    it 'assign set return to' do
      get :search, params: { program_id: @program.id, return_to: 'something/something', section_id: @section.id }
      expect(assigns(:return_to)).to eq('something/something')
    end
  end

  describe '#search_by' do
    let(:instructor) { build_stubbed(:instructor) }
    let(:school) { build_stubbed(:school) }
    let(:program) { build_stubbed(:program) }
    let(:section) { build_stubbed(:section) }
    let(:params) do
      { 'return_to' => 'something/something',
        'section_id' => section.id.to_s,
        'search_str' => 'abc@abc.abc',
        'program_id' => program.id.to_s }
    end
    let(:enabler_class) do
      class_double(EnrollmentEngine::ConcurrentEnrollmentEnabler).as_stubbed_const
    end
    let(:ce_enabler) do
      instance_double(
        EnrollmentEngine::ConcurrentEnrollmentEnabler,
        enforce_single_enrollment?: true
      )
    end

    before do
      allow(instructor).to receive(:setting)
      allow(instructor).to receive(:has_current_access_to?).and_return(true)
      fake_login(instructor)

      allow(controller).to receive(:current_user).and_return(instructor)
      allow(controller).to receive(:current_program).and_return(program)

      allow(instructor).to receive(:schools).and_return([school])

      allow(AddableStudentsPresenter).to receive(:new)
        .and_return(double(AddableStudentsPresenter))

      allow(Section).to receive(:find).and_return(section)
      allow(enabler_class).to(
        receive(:new).with(course_to: section.course, enroll_by: :instructor).and_return(ce_enabler)
      )
    end

    def do_request(opts = {})
      get :search_by, params: params.merge(opts)
    end

    it 'creates a presenter' do
      expect(AddableStudentsPresenter).to receive(:new)
        .with([school], program, hash_including(params))
        .and_return(double(AddableStudentsPresenter))
      do_request
    end

    it 'calls enforce_single_enrollment? on ConcurrentEnrollmentEnabler' do
      do_request

      expect(ce_enabler).to have_received(:enforce_single_enrollment?)
    end

    it 'renders a template' do
      do_request
      expect(response).to render_template 'instructor/student/_search_results'
    end
  end
end
