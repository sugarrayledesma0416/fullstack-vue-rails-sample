describe InstructorTocPresenter do
  include Rails.application.routes.url_helpers

  let(:program) { build_stubbed(:program, id: 49) }
  let(:course) { build_stubbed(:course, program: program) }
  let(:section) { build_stubbed(:section, course: course) }
  let(:lesson) { build_stubbed(:lesson_with_toc_entries) }
  let(:focus) { instance_double(Focus, sections: [section], course: course) }

  # rubocop:disable RSpec/Focus
  let(:presenter) do
    described_class.new(program, 'instructor', focus, { all_units: 'true' }, {})
  end

  before do
    allow(program).to receive(:best_display_lesson).and_return(lesson)
    allow(lesson).to receive(:program).and_return(program)
    allow(section).to receive(:program).and_return(program)
  end

  describe '.new' do
    it 'inits current_user' do
      expect(
        described_class.new(program, 'instructor', focus, {}, {}).current_user
      ).to eq('instructor')
    end

    it 'inits program' do
      expect(
        described_class.new(program, 'instructor', focus, {}, {}).program
      ).to eq(program)
    end

    it 'inits sections' do
      expect(
        described_class.new(program, 'instructor', focus, {}, {}).sections
      ).to eq([section])
    end

    it 'raises error when valid params are not passed' do
      expect do
        described_class.new(nil, 'instructor', 'dontcare', {}, {})
      end.to raise_error 'not all parameters are valid'
      expect do
        described_class.new('program', nil, 'dontcare', {}, {})
      end.to raise_error 'not all parameters are valid'
      expect do
        described_class.new('program', 'user', 'dontcare', nil, {})
      end.to raise_error 'not all parameters are valid'
    end
  end

  # rubocop:enable RSpec/Focus

  describe '#base_url' do
    it 'returns section toc url' do
      expect(presenter.base_url).to eq(instructor_toc_path(program))
    end

    it 'appends option to the url' do
      options = { all_units: true, activity_library: 'course' }
      expect(presenter.base_url(options)).to eq(instructor_toc_path(program, options))
    end
  end

  describe '#base_url_params' do
    it 'returns hash with param' do
      expect(presenter.base_url_params).to eq(program_id: program.id)
    end
  end

  describe '#component_header_class' do
    let(:activities) { [build_stubbed(:activity)] }

    it "returns 'toc_location_component' when there are assignable " \
       'activities within a component' do
      expect(presenter).to receive(:any_assignable?).with(activities).and_return(true)
      expect(presenter.component_header_class(activities)).to eq('toc_location_component')
    end

    it "returns 'toc_location_component unassignable_component' when there " \
       'are no assignable activities within a component' do
      expect(presenter).to receive(:any_assignable?).with(activities).and_return(false)
      expect(presenter.component_header_class(activities)).to eq(
        'toc_location_component unassignable_component'
      )
    end
  end

  describe '#show_google_classroom_button' do
    describe 'if Google Classroom configuration is Enabled for school and Enabled for course' do
      let(:school) { create(:school, share_to_google_classroom: true) }
      let(:course) do
        create(:course, program: program,
                        school: school,
                        share_to_google_classroom: true)
      end

      it 'returns true' do
        expect(presenter.show_google_classroom_button?).to be_truthy
      end
    end

    describe 'if Google Classroom configuration is Enabled for school and Disabled for course' do
      let(:school) { create(:school, share_to_google_classroom: true) }
      let(:course) do
        create(:course, program: program,
                        school: school,
                        share_to_google_classroom: false)
      end

      it 'returns false' do
        expect(presenter.show_google_classroom_button?).to be_falsey
      end
    end

    describe 'if Google Classroom configuration is Disabled for school and Enabled for course' do
      let(:school) { create(:school, share_to_google_classroom: false) }
      let(:course) do
        create(:course, program: program,
                        school: school,
                        share_to_google_classroom: true)
      end

      it 'returns false' do
        expect(presenter.show_google_classroom_button?).to be_falsey
      end
    end

    describe 'if Google Classroom configuration is Enabled for school and Enabled for course
      but no course is in focus' do
      let(:school) { create(:school, share_to_google_classroom: true) }
      let(:course) do
        create(:course, program: program,
                        school: school,
                        share_to_google_classroom: true)
      end
      let(:focus) { instance_double(Focus, sections: [], course: nil) }

      it 'returns false' do
        expect(presenter.show_google_classroom_button?).to be_falsey
      end
    end
  end
end
