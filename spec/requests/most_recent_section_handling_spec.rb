require 'requests/login_helper_methods'

describe MostRecentSectionHandling do
  let(:student) { create(:student) }
  let(:instructor) { create(:instructor) }
  let(:course) { create(:course, owner: instructor, program:) }
  let(:section) { create(:section, course:, instructor:) }
  let(:other_section) { create(:section, course:, instructor:) }

  describe 'storing most recent section' do
    let(:program) { create(:program) }

    context 'when logged in as a student,' do
      before do
        create(:active_enrollment, section:, user: student)
        create(:active_enrollment, section: other_section, user: student)
        log_in_user_with_access_to_programs(student, [program])
      end

      it 'stores the section_id parameter in the session, keyed on the program' do
        get course_section_path(course_id: course.id, section_id: section.id)

        expect(session[:most_recent_section]).to eq(
          { "program_#{program.id}" => section.id }
        )
      end

      it 'updates the session value if a new section is visited' do
        new_section = create(:section, course:)

        get course_section_path(course_id: course.id, section_id: section.id)

        expect(session[:most_recent_section]).to eq(
          { "program_#{program.id}" => section.id }
        )

        get course_section_path(course_id: course.id, section_id: new_section.id)

        expect(session[:most_recent_section]).to eq(
          { "program_#{program.id}" => new_section.id }
        )
      end

      it 'does not update the session value keyed for a different ' \
         'program to the one being visited' do
        other_program = create(:program)

        other_program_course = create(:course, owner: instructor, program: other_program)
        other_program_section = create(:section, course: other_program_course)

        stub_user_access_to_programs(student, [program, other_program])

        get course_section_path(course_id: course.id, section_id: section.id)

        expect(session[:most_recent_section]).to eq(
          { "program_#{program.id}" => section.id }
        )

        get course_section_path(
          course_id: other_program_course.id,
          section_id: other_program_section.id
        )

        expect(session[:most_recent_section]).to eq(
          {
            "program_#{other_program.id}" => other_program_section.id,
            "program_#{program.id}" => section.id
          }
        )
      end
    end

    context 'when logged in as an instructor,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'does not set the session value' do
        log_in_user_with_access_to_programs(instructor, [program])

        get course_section_path(course_id: course.id, section_id: section.id)
        expect(session[:most_recent_section]).to be_blank
      end
    end
  end

  describe 'retrieving most recent section' do
    let(:program) { create(:program_with_lessons) }
    let(:lesson) { program.units.first.lessons.first }

    context 'when logged in as a student,' do
      before do
        create(:active_enrollment, section:, user: student)
        create(:active_enrollment, section: other_section, user: student)
        log_in_user_with_access_to_programs(student, [program])

        # Hit this in order to store the most_recent_section in the session.
        get course_section_path(course_id: course.id, section_id: section.id)
      end

      it 'assigns the section from the most_recent_section session value' do
        get "/#{program.id}/vocab_tools/units"

        expect(assigns(:current_section)).to eq(section)
      end
    end

    context 'when logged in as an instructor,' do
      before { log_in_user_with_access_to_programs(instructor, [program]) }

      it 'does not try to use the most_recent_section session variable' do
        get "/#{program.id}/vocab_tools/units"

        expect(assigns(:current_section)).to be_zero
      end
    end
  end
end
