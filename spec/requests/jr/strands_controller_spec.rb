require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe Jr::StrandsController do
  let(:student) { create(:student) }
  let(:program) { create(:program) }
  let(:instructor) { create(:instructor) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:unit) { create(:unit, program: program) }
  let(:lesson) { create(:lesson, name: 'Lesson 1', unit: unit) }
  let(:strand) { create(:toc_entry, short_title: 'Con', title: '<b>Contextos</b>') }

  let(:concept) do
    create(
      :concept,
      id: strand.location,
      lesson: lesson,
      name: strand.title,
      program: program
    )
  end

  before do
    lesson.toc_entries = [strand]
    lesson.save!
    create(:active_enrollment, section: section, user: student)
  end

  describe 'GET /show' do
    let(:target_path) do
      jr_section_program_strand_path(
        id: concept.id, program_id: program.id, section_id: section.id
      )
    end

    def do_request
      get target_path
    end

    include_examples 'require logged in user'

    context 'with a logged in user' do
      before do
        log_in_user_with_access_to_programs(student, [program])
      end

      it 'renders the show view for the specified strand' do
        do_request

        expect(response).to be_ok

        expect(response).to render_template(:show)

        # Can't compare equality of strand objects because saving the strand
        # into the lesson xml alters it. See the to_xml method in LessonXML
        # module.
        expect(assigns(:strand).location).to eq(strand.location)
        expect(assigns(:concept)).to eq(concept)
        expect(assigns(:lesson)).to eq(lesson)

        # It strips any tags out of the lesson or strand name, because there
        # shouldn't be any html inside the <title> tag of page.
        expect(assigns(:page_title)).to eq('Lesson 1 | Contextos')

        expect(assigns(:menu_location)).to eq('content')

        presenter = assigns(:presenter)
        expect(presenter).to be_a(Jr::TocPresenter)
        expect(presenter).to have_attributes(
          course: course,
          current_user: student,
          lesson: lesson,
          program: program,
          section: section
        )
        expect(presenter.strand.location).to eq(strand.location)

        expect(session[:activity_return]).to eq(
          'label' => 'Return to Activities', 'url' => target_path
        )
      end
    end
  end
end
