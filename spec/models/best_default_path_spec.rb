describe BestDefaultPath do
  include Rails.application.routes.url_helpers

  let(:user) { build_stubbed(:user) }
  let(:program) { build_stubbed(:program) }

  describe '.best_default_path' do
    let(:mock_instance) { instance_double(described_class) }
    let(:path) { '/blah/blah' }

    before do
      allow(described_class).to receive(:new).and_return(mock_instance)
      allow(mock_instance).to receive(:best_default_path).and_return(path)
    end

    it 'creates a new BestDefaultPath instance' do
      described_class.best_default_path(user, program, nil, {})

      expect(described_class).to have_received(:new).with(user, program, nil, {})
    end

    it 'calls best_default_path on that instance' do
      described_class.best_default_path(user, program, nil, {})

      expect(mock_instance).to have_received(:best_default_path)
    end

    it 'returns the result of calling best_default_path on that instance' do
      result = described_class.best_default_path(user, program, nil, {})

      expect(result).to eq(path)
    end
  end

  describe '#best_default_path' do
    context 'with an instructor,' do
      let(:user) { build_stubbed(:instructor) }

      it 'returns the instructor dashboard path for the specified program ' \
         'if it is not nil' do
        result = described_class.new(user, program, nil, {}).best_default_path

        expect(result).to eq(instructor_dashboard_path(program))
      end

      context 'when program is nil,' do
        it 'returns the instructor dashboard path for the first ' \
           'program the instructor has access to' do
          allow(user).to receive(:programs).and_return([program])

          result = described_class.new(user, nil, nil, {}).best_default_path

          expect(result).to eq(instructor_dashboard_path(program))
        end

        it 'returns the UA Home path if the instructor has no program access' do
          allow(user).to receive(:programs).and_return([])

          result = described_class.new(user, nil, nil, {}).best_default_path

          expect(result).to eq(ua_home_path)
        end
      end
    end

    context 'with a student,' do
      let(:user) { build_stubbed(:student) }

      context 'when the specified section is not nil,' do
        let(:section) { build_stubbed(:section) }

        context 'when the specified section is the section in which the ' \
                'student is actively enrolled,' do
          before do
            allow(user).to receive(:active_section?).and_return(true)
          end

          it 'returns the normal student dashboard path if the program is not ' \
             'Supersite Junior' do
            allow(program).to receive(:supersite_junior?).and_return(false)

            result = described_class.new(user, program, section, {}).best_default_path

            expect(result).to eq(
              course_section_path(
                course_id: section.course_id,
                section_id: section.id
              )
            )
          end

          it 'returns the Supersite Junior dashboard path if the program is ' \
             'Supersite Junior' do
            allow(program).to receive(:supersite_junior?).and_return(true)

            result = described_class.new(user, program, section, {}).best_default_path

            expect(result).to eq(
              jr_course_section_path(
                course_id: section.course_id,
                section_id: section.id
              )
            )
          end
        end

        context 'when the specified section is not the section in which the ' \
                'student is actively enrolled,' do
          let(:other_section) { build_stubbed(:section) }

          before do
            allow(user).to receive(:active_section?).and_return(false)
          end

          context 'when the student is actively enrolled in a section for ' \
                  'the specified program,' do
            before do
              allow(user).to receive(:current_section_in_program)
                .and_return(other_section)
            end

            it 'returns the normal student dashboard path for their active ' \
               'section if the program is not Supersite Junior' do
              allow(program).to receive(:supersite_junior?).and_return(false)

              result = described_class.new(user, program, section, {}).best_default_path

              expect(result).to eq(
                course_section_path(
                  course_id: other_section.course_id,
                  section_id: other_section.id
                )
              )
            end

            it 'returns the Supersite Junior dashboard path for their active ' \
               'section if the program is Supersite Junior' do
              allow(program).to receive(:supersite_junior?).and_return(true)

              result = described_class.new(user, program, section, {}).best_default_path

              expect(result).to eq(
                jr_course_section_path(
                  course_id: other_section.course_id,
                  section_id: other_section.id
                )
              )
            end
          end

          context 'when the student is not actively enrolled in a section ' \
                  'for the specified program,' do
            before do
              allow(user).to receive(:current_section_in_program)
                .and_return(nil)
            end

            context 'when the student has access to the specified program, ' do
              before do
                allow(user).to receive(:accessible_program?).and_return(true)
              end

              it 'returns the no-section dashboard path if the program is ' \
                 'not Supersite Junior' do
                allow(program).to receive(:supersite_junior?).and_return(false)

                result = described_class.new(user, program, nil, {}).best_default_path

                expect(result).to eq(
                  no_section_student_dashboard_path(0, program.id)
                )
              end

              it 'returns the Supersite Junior ToC if the program is ' \
                 'Supersite Junior' do
                allow(program).to receive(:supersite_junior?).and_return(true)

                result = described_class.new(user, program, nil, {}).best_default_path

                expect(result).to eq(
                  jr_section_program_content_path(
                    section_id: 0, program_id: program.id
                  )
                )
              end
            end

            it 'returns the UA Home path when the student does not have access' \
               'to the specified program' do
              allow(user).to receive(:accessible_program?).and_return(false)
              result = described_class.new(user, program, section, {}).best_default_path

              expect(result).to eq(ua_home_path)
            end
          end
        end
      end

      context 'when the specified section is nil,' do
        context 'when the user has access to the specified program,' do
          before do
            allow(user).to receive(:accessible_program?).and_return(true)
          end

          it 'returns the no-section dashboard path if the program is not ' \
             'Supersite Junior' do
            allow(program).to receive(:supersite_junior?).and_return(false)

            result = described_class.new(user, program, nil, {}).best_default_path

            expect(result).to eq(
              no_section_student_dashboard_path(0, program.id)
            )
          end

          it 'returns the Supersite Junior ToC if the program is Supersite ' \
             'Junior' do
            allow(program).to receive(:supersite_junior?).and_return(true)

            result = described_class.new(user, program, nil, {}).best_default_path

            expect(result).to eq(
              jr_section_program_content_path(
                section_id: 0, program_id: program.id
              )
            )
          end
        end

        it 'returns the UA Home path the user does not have access to ' \
           'the specified program' do
          allow(user).to receive(:accessible_program?).and_return(false)

          result = described_class.new(user, program, nil, {}).best_default_path

          expect(result).to eq(ua_home_path)
        end
      end

      it 'returns the UA Home path when section and program are nil' do
        result = described_class.new(user, nil, nil, {}).best_default_path

        expect(result).to eq(ua_home_path)
      end
    end
  end
end
