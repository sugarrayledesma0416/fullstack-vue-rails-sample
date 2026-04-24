describe GradebookStudent do
  let(:gb_student) { described_class.new(student, nil, program.id, [section]) }

  let(:student)  { create(:student) }
  let(:program)  { create(:program) }
  let(:section) { create(:section, course: create(:course, program:)) }

  def user_license_double(user_id, grace_period, expired)
    instance_double(
      Maestro::UserLicense, user_id: user_id, grace_period?: grace_period, expired?: expired
    )
  end

  # Reload the student to update enrollment associations.
  before { student.reload }

  # Reset the class instance variable to prevent leaking instance_doubles.
  after { GradebookStudent.instance_variable_set("@all_user_licenses", nil) }

  it 'responds as a Student object' do
    expect(gb_student).to be_a Student
  end

  it 'contains a student record' do
    expect(gb_student.student).to eq(student)
  end

  it 'passes Student methods on to the student object' do
    expect(gb_student.full_name).to eq(student.full_name)
  end

  describe '.decorate' do
    let(:decorated_result) { described_class.decorate(student, program, [section]) }

    before do
      allow(Maestro::UserLicense).to receive(:all_for_users_in_program).and_return([])
    end

    context 'when students is an array of Students' do
      let(:decorated_result) do
        described_class.decorate([other_student, student], program, [section])
      end
      let(:other_student) { create(:student) }
      let(:other_gb_student) { described_class.new(other_student, nil, program.id, [section]) }


      it 'sends the user_ids and program info to Maestro::UserLicense' do
        decorated_result
        expect(Maestro::UserLicense).to have_received(:all_for_users_in_program)
          .with([other_student.guid, student.guid], program.id)
      end

      it 'returns an array of GradebookStudents with the same order as students' do
        expect(decorated_result).to eq([other_gb_student, gb_student])
      end

      context 'when students have different access' do
        before do
          create(:enrollment_with_access, user: student, section:)
        end

        it 'decorates each student with the correct access' do
          expect(decorated_result.to_a.map(&:sufficient_access?)).to eq([nil, true])
        end
      end
    end

    context 'when students is a single Student' do
      it 'sends the expected info to Maestro::UserLicense' do
        decorated_result
        expect(Maestro::UserLicense).to have_received(:all_for_users_in_program)
          .with([student.guid], program.id)
      end

      it 'returns a GradebookStudent' do
        expect(decorated_result).to eq(gb_student)
      end
    end

    context 'when a student has enough access in a specified section' do
      before do
        create(:enrollment_with_access, user: student, section:)
      end

      it 'decorates the student with sufficient access' do
        expect(decorated_result.sufficient_access?).to be_truthy
      end
    end

    context 'when a student has enough access in a different section' do
      before do
        # Insufficient access in the specified section.
        create(:enrollment, user: student, section:, sufficient_access: false)
        # Sufficient access in a different course and section.
        create(
          :enrollment_with_access,
          user: student,
          section: create(:section, course: create(:course, program:))
        )
      end

      it 'decorates the student with insufficient access' do
        expect(decorated_result.sufficient_access?).to be_falsey
      end
    end

    context 'when a student has enough access to another program' do
      before do
        create(:enrollment, user: student, section:, sufficient_access: false)
        other_program = create(:program)
        create(
          :enrollment_with_access,
          user: student,
          section: create(:section, course: create(:course, program: other_program))
        )
      end

      it 'decorates the student with insufficient access' do
        expect(decorated_result.sufficient_access?).to be_falsey
      end
    end

    # Demonstrate backward compatibility.
    context 'when the sections parameter is not specified' do
      let(:decorated_result) { described_class.decorate(student, program) }

      context 'when a student has access to the program through any section' do
        before do
          create(:enrollment_with_access, user: student, section:)
        end

        it 'decorates the student with sufficient access' do
          expect(decorated_result.sufficient_access?).to be_truthy
        end
      end
    end

    context 'when the student enrollment has insufficient access' do
      before do
        create(:enrollment, user: student, section:, sufficient_access: false)
      end

      context 'when the student has no user license' do
        it 'returns a GradebookStudent with insufficient access' do
          expect(decorated_result.sufficient_access?).to be_falsey
        end
      end

      context 'when the student has a user license' do
        let(:user_licenses) { [user_license] }
        let(:user_license) { user_license_double(student.id, grace_period, expired) }

        before do
          allow(Maestro::UserLicense).to receive(:all_for_users_in_program)
            .and_return(user_licenses)
        end

        context 'when the user license has no grace period' do
          let(:grace_period) { false }
          let(:expired) { false }

          it 'returns a GradebookStudent with insufficient access' do
            expect(decorated_result.sufficient_access?).to be_falsey
          end
        end

        context 'when the user license has a grace period but is expired' do
          let(:grace_period) { true }
          let(:expired) { true }

          it 'returns a GradebookStudent with insufficient access' do
            expect(decorated_result.sufficient_access?).to be_falsey
          end
        end

        context 'when the user license has a grace period and is not expired' do
          let(:grace_period) { true }
          let(:expired) { false }

          it 'returns a GradebookStudent with sufficient access' do
            expect(decorated_result.sufficient_access?).to be_truthy
          end
        end
      end
    end

    context 'when the student has enrollments with different access in multiple programs' do
      before do
        # Sufficient access to the target program
        create(:enrollment_with_access, user: student, section:)
        # Insufficient access to another program
        other_program = create(:program)
        other_section = create(:section, course: create(:course, program: other_program))
        create(:enrollment, user: student, section: other_section, sufficient_access: false)
      end

      it 'decorates with access for the correct program' do
        expect(decorated_result.sufficient_access?).to be_truthy
      end
    end

    context 'when some students with insufficient enrollment access have a grace period' do
      let(:decorated_result) { described_class.decorate([student, other_student], program, [section])}

      let(:other_student) { create(:student) }
      let(:user_licenses) { [user_license, other_user_license] }
      let(:user_license) { user_license_double(student.id, false, false) }
      let(:other_user_license) { user_license_double(other_student.id, true, false) }

      before do
        # Insufficient access through enrollments for each program
        create(:enrollment, user: student, section:, sufficient_access: false)
        create(:enrollment, user: other_student, section:, sufficient_access: false)

        allow(Maestro::UserLicense).to receive(:all_for_users_in_program)
          .and_return(user_licenses)
      end

      it 'decorates each student with the correct access' do
        expect(decorated_result.to_a.map(&:sufficient_access?)).to eq([nil, other_user_license])
      end
    end

    # NOTE: Because Maestro::UserLicense response is stubbed, this case is a bit silly.
    context 'when the student has different grace periods in different programs' do
      let(:other_program) { create(:program) }
      let(:other_section) { create(:section, course: create(:course, program: other_program)) }

      let(:user_licenses) { [user_license] }
      let(:user_license) { user_license_double(student.id, false, true) }
      let(:user_other_license) { user_license_double(student.id, true, false) }

      before do
        # Insufficient access through enrollments for each program
        create(:enrollment, user: student, section:, sufficient_access: false)
        create(:enrollment, user: student, section: other_section, sufficient_access: false)

        allow(Maestro::UserLicense).to receive(:all_for_users_in_program)
          .and_return(user_licenses)
      end

      it 'decorates with access for the correct program' do
        allow(Maestro::UserLicense).to receive(:all_for_users_in_program)
          .and_return([user_license])
        program_result = described_class.decorate(student, program, [section])
        expect(program_result.sufficient_access?).to be_falsey
      end
    end
  end

  describe '#sufficient_access?' do
    context 'when no grace period is provided' do
      context 'when the student is not enrolled in a specified section' do
        before do
          other_section = create(:section, course: create(:course, program:))
          create(:enrollment_with_access, user: student, section: other_section)
        end

        it 'is falsey' do
          expect(gb_student.sufficient_access?).to be_falsey
        end
      end

      context 'when the sufficient access enrollment is not active' do
        before do
          create(:completed_enrollment, user: student, section:, sufficient_access: true)
        end

        it 'is falsey' do
          expect(gb_student.sufficient_access?).to be_falsey
        end
      end

      context 'when the student is enrolled with sufficient access in a specified section' do
        before do
          create(:enrollment_with_access, section:, user: student)
        end

        it 'is truthy' do
          expect(gb_student.sufficient_access?).to be_truthy
        end
      end

      # Included to check backward compatibility.
      context 'when the student is enrolled with sufficient access and no sections are specified' do
        let(:gb_student) { described_class.new(student, nil, program.id) }

        context 'when the enrollment is in the same program' do
          before do
            create(:enrollment_with_access, user: student, section:)
          end

          it 'is truthy' do
            expect(gb_student.sufficient_access?).to be_truthy
          end
        end

        context 'when the enrollment is in a different program' do
          before do
            other_program = create(:program)
            other_section = create(:section, course: create(:course, program: other_program))
            create(:enrollment_with_access, user: student, section: other_section)
          end

          it 'is falsey' do
            expect(gb_student.sufficient_access?).to be_falsey
          end
        end
      end
    end

    context 'when the enrollment has insufficient access and a grace period is provided' do
      let(:gb_student) { described_class.new(student, grace_period, program.id, [section]) }

      # NOTE: `#sufficient_access?` does not check UserLicense state.
      #       The `.decorate` method determines which UserLicenses are passed
      #       to `#sufficient_access?`.
      let(:grace_period) { instance_double(Maestro::UserLicense) }

      before do
        create(:enrollment,  user: student, section:, sufficient_access: false)
      end

      it 'is truthy' do
        expect(gb_student.sufficient_access?).to be_truthy
      end
    end
  end

  describe '#enrolled_sections_by_name' do
    let(:enrolled_sections) { gb_student.enrolled_sections_by_name }

    context 'when the student is not enrolled in a specified section' do
      before do
        other_section = create(:section, course: create(:course, program:))
        create(:enrollment_with_access, user: student, section: other_section)
      end

      it 'returns an empty array' do
        expect(enrolled_sections).to be_empty
      end
    end

    context 'when the student is enrolled in a specified section' do
      before do
        create(:enrollment_with_access, user: student, section:)
      end

      it 'returns the section' do
        expect(enrolled_sections).to eq([section])
      end
    end

    context 'when the student is enrolled in more than one specified section' do
      let(:gb_student) do
         described_class.new(student, nil, program.id, [section_xyz, section_abc])
      end

      let(:course) { create(:course, program:) }
      let(:section_abc) { create(:section, course:, name: 'abc') }
      let(:section_xyz) { create(:section, course:, name: 'xyz') }

      before do
        create(:enrollment_with_access, user: student, section: section_xyz)
        create(:enrollment_with_access, user: student, section: section_abc)
      end

      it 'returns the sections in alphabetical order' do
        expect(enrolled_sections).to eq([section_abc, section_xyz])
      end
    end
  end
end
