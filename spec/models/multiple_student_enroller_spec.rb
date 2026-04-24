describe MultipleStudentEnroller do
  # Stub external dependencies
  let(:student_1) { build_stubbed(:student) }
  let(:student_2) { build_stubbed(:student) }
  let(:student_3) { build_stubbed(:student) }
  let(:student_4) { build_stubbed(:student) }
  let(:student_5) { build_stubbed(:student) }
  let(:students) { [student_1, student_2, student_3, student_4, student_5] }
  let(:selected_student_ids) { students.map(&:id) }
  let(:school) { build_stubbed(:school) }
  let(:section) { build_stubbed(:section) }

  # initialize instance for testing
  let(:program_id) { 79 }
  let(:enroller_params) do
    { selected_section_id: section.id.to_s,
      program_id: program_id,
      selected_student_ids: selected_student_ids.map(&:to_s) }
  end
  let(:enroller) { described_class.new(enroller_params) }

  # Variables for testing the interface between classes
  let(:flash_messages) { {banner: 'dummy'} }
  # default values will be changed to test params send to FlashMessageGenerator
  let(:enrollment_map) { { success: [], failed: [], insufficient_access: [], hard_cap_reached: [] } }

  describe '#enroll' do

    before do
      allow(Section).to receive(:find).and_return(section)
      allow(section).to receive(:school).and_return(school)
      allow(Enrollment).to receive(:enroll).and_return(enrollment_map)
      allow(MultipleStudentEnroller::FlashMessageGenerator).to receive(:generate_messages).and_return(flash_messages)
      allow(Student).to receive(:where).with(id: [student_1.id, student_2.id, student_3.id, student_4.id, student_5.id]).and_return([student_1, student_2, student_3, student_4, student_5])
    end

    # Testing the direct responsibilities of #enroll, and its public side effects

    it 'enrolls students' do
      expect(Enrollment).to receive(:enroll).with(students, section)
      enroller.enroll
    end

    context 'When there are no students to enroll' do
      let(:selected_student_ids) { [] }

      it 'does not enroll students' do
        expect(Enrollment).not_to receive(:enroll)
        enroller.enroll
      end

      it 'does not make any banners' do
        expect(MultipleStudentEnroller::FlashMessageGenerator).not_to receive(:generate_messages)
        enroller.enroll
      end

    end

    it 'sets flash messages' do
      enroller.enroll
      expect(enroller.flash_messages).to eq(flash_messages)
    end

    # Testing interface with FlashMessageGenerator

    it 'generates and sets flash messages' do
      expect(MultipleStudentEnroller::FlashMessageGenerator).to receive(:generate_messages)
      enroller.enroll
    end

    it 'passes the section name' do
      expect(MultipleStudentEnroller::FlashMessageGenerator).to receive(:generate_messages).with(anything, section.name)
      enroller.enroll
    end

    context 'When there are failed enrollments' do
      let(:enrollment_map) { { success: [], failed: [student_1, student_2], insufficient_access: [], hard_cap_reached: [student_3, student_4, student_5] } }

      it 'passes the failure counts (hard cap and normal) separately' do
        expect(MultipleStudentEnroller::FlashMessageGenerator).to receive(:generate_messages).with(hash_including(failure: 2, hard_cap: 3), anything)
        enroller.enroll
      end
    end

    context 'When there are students with insufficient access' do
      let(:enrollment_map) { { success: [student_1, student_2], failed: [], insufficient_access: [student_3], hard_cap_reached: [] } }

      it 'includes the insufficient access count in the success count' do
        expect(MultipleStudentEnroller::FlashMessageGenerator).to receive(:generate_messages).with(hash_including(success: 3, insufficient_access: 1), anything)
        enroller.enroll
      end
    end

  end
end

# Values in enrollment map json for various cases (students and subset
# represent arrays of students):
#
# total success:
# { success: students, failed: [], insufficient_access: [], hard_cap_reached: [] }
#
# successfull enrollments with insufficient access:
# { success: [], failed: [], insufficient_access: students, hard_cap_reached: [] }
#
# total failure, non-hard cap:
# { success: [], failed: students, insufficient_access: [], hard_cap_reached: [] }
#
# total failure, hard-cap:
# { success: [], failed: [], insufficient_access: [], hard_cap_reached: students}
#
# partial success, non-hard cap:
# { success: subset, failed: subset, insufficient_access: [], hard_cap_reached: []}
#
# partial success, hard-cap failure
# { success: subset, failed: [], insufficient_access: [], hard_cap_reached: subset}

describe MultipleStudentEnroller::FlashMessageGenerator do
  let(:section_name) { 'Section Name' }  # should not have numbers in it
  let(:success) { 1 } # success is the default case
  let(:failure) { 0 }
  let(:hard_cap) { 0 }
  let(:insufficient_access) { 0 }
  let(:message_counts) {
    {
      success: success,
      failure: failure,
      hard_cap: hard_cap,
      insufficient_access: insufficient_access
    }
  }

  describe '#generate_messages' do

    it 'returns the flash_messages hash' do
      flash_messages = described_class.generate_messages(message_counts, section_name)
      expect(flash_messages).to be_a_kind_of(Hash)
    end

    it 'returns an array of messages for each type' do
      flash_messages = described_class.generate_messages(message_counts, section_name)
      expect(flash_messages[:notice]).to be_a_kind_of(Array)
    end

    context 'When all attempted enrollments succeed' do

      it 'generates only a success notice' do
        flash_messages = described_class.generate_messages(message_counts, section_name)
        expect(flash_messages.keys).to eq [:notice]
      end

      it 'states the section students were added to' do
        success_message = described_class.generate_messages(message_counts, section_name)[:notice].join(' ')

        expect(success_message).to include(section_name)
      end

      it 'has correct grammar for one student' do
        success_message = described_class.generate_messages(message_counts, section_name)[:notice].join(' ')

        expect(success_message).to include("<b>1 student</b> added to")
      end

      context 'When there is more than one student' do
        let(:success) { 2 }

        it 'has correct grammar' do
          success_message = described_class.generate_messages(message_counts, section_name)[:notice].join(' ')

          expect(success_message).to include("2 students")
          expect(success_message).to include("added to")
        end

      end
    end

    context 'When all attempted enrollments failed' do
      # This does not cover hard cap related failures
      let(:failure) { 1 }
      let(:success) { 0 }

      it 'generates only an error' do
        flash_messages = described_class.generate_messages(message_counts, section_name)
        expect(flash_messages.keys).to eq [:error]
      end

      it 'has correct grammar for one student' do
        error_message = described_class.generate_messages(message_counts, section_name)[:error].join(' ')

        expect(error_message).to eq("Enrollment failed for <b>1 student</b>.")
      end

      it 'does not reference the hard cap' do
        described_class.generate_messages(message_counts, section_name)
        error_message = described_class.generate_messages(message_counts, section_name)[:error].join(' ')

        expect(error_message.downcase).not_to include("site license")
      end

      context 'When there is more than one student' do
        let(:failure) { 2 }

        it 'has correct grammar' do
          error_message = described_class.generate_messages(message_counts, section_name)[:error].join(' ')

          expect(error_message).to include("2 students")
        end
      end
    end

    context 'When all attempted enrollments failed because the hard cap was hit' do
      let(:hard_cap) { 1 }
      let(:success) { 0 }

      it 'generates only an error' do
        flash_messages = described_class.generate_messages(message_counts, section_name)
        expect(flash_messages.keys).to eq [:error]
      end

      it 'specifies that the failure is due to site license issues' do
        described_class.generate_messages(message_counts, section_name)
        error_message = described_class.generate_messages(message_counts, section_name)[:error].join(' ')

        expect(error_message.downcase).to include("site license")
      end

      it 'has correct grammar for one student' do
        described_class.generate_messages(message_counts, section_name)
        error_message = described_class.generate_messages(message_counts, section_name)[:error].join(' ')

        expect(error_message).to include("failed for <b>1 student</b>")
        expect(error_message).not_to include("students")
      end

      context 'When there is more than one student' do
        let(:hard_cap) { 2 }

        it 'has correct grammar' do
          error_message = described_class.generate_messages(message_counts, section_name)[:error].join(' ')

          expect(error_message).to include("2 students")
        end
      end
    end

    context 'When some enrollments failed and some succeeded' do
      let(:success) { 3 }
      let(:failure) { 2 }

      it 'should create a success message for the successes' do
        described_class.generate_messages(message_counts, section_name)
        success_message = described_class.generate_messages(message_counts, section_name)[:notice].join(' ')

        expect(success_message).to include("3 students")
      end

      it 'should create a failure message for the failures' do
        described_class.generate_messages(message_counts, section_name)
        error_message = described_class.generate_messages(message_counts, section_name)[:error].join(' ')

        expect(error_message).to include("2 students")
      end
    end

    context 'When some enrolled students had insufficient access' do
      let(:insufficient_access) { 1 }
      # success is also 1

      it 'should create a success message for the successes' do
        described_class.generate_messages(message_counts, section_name)
        success_message = described_class.generate_messages(message_counts, section_name)[:notice].join(' ')

        expect(success_message).to include("1 student")
      end

      it 'has correct grammar for one student' do
        access_message = described_class.generate_messages(message_counts, section_name)[:warning].join(' ')

        expect(access_message).to eq("<b>1 student</b> has insufficient access to complete your course.")
      end

      context 'when there is more than one student' do
        let(:insufficient_access) { 2 }
        it 'should pluralize correctly on the warning banner' do
          access_message = described_class.generate_messages(message_counts, section_name)[:warning].join(' ')

          expect(access_message).to include("2 students")
          expect(access_message).to include("have")
        end
      end

      context 'When it receives only an insufficient access count' do
        # We expect MultipleStudentEnroller to handle the redundancy
        # between success and insufficient access.
        # FlashMessageGenerator should only make success banners if
        # told to.

        let(:success) { 0 }
        it 'generates only a warning' do
          expect(described_class.generate_messages(message_counts, section_name).keys).to eq [:warning]
        end
      end

    end

  end
end
