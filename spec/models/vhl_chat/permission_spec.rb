module VhlChat
  describe Permission do
    let(:program) { instance_double(Program) }
    let(:section) { instance_double(Section, non_zero?: true) }
    let(:access_guardian) { instance_double(AccessGuardian) }

    before do
      allow(AccessGuardian).to receive(:new).and_return(access_guardian)
    end

    describe '#user_can_access_live_chat?' do
      let(:user) { build_stubbed(:student) }

      context 'when the user does not have a live chat license' do
        it 'returns false' do
          allow(access_guardian).to receive(:has_live_chat?).and_return(false)
          permit = Permission.new(user, program, access_guardian, section)
          allow(permit).to receive(:live_chat_enabled?).and_return(true)
          expect(permit.user_can_access_live_chat?).to be_falsey
        end
      end

      context 'when the user has a live chat license' do
        let(:permit) { Permission.new(user, program, access_guardian, section) }

        before do
          allow(access_guardian).to receive(:has_live_chat?).and_return(true)
        end

        context 'when the user is an instructor' do
          it 'returns true' do
            allow(user).to receive(:instructor?).and_return(true)
            expect(permit.user_can_access_live_chat?).to be_truthy
          end
        end

        context 'when the user is not an instructor' do
          before do
            allow(user).to receive(:instructor?).and_return(false)
          end

          context 'when live chat is enabled for the current course' do
            it 'returns true' do
              allow(permit).to receive(:live_chat_enabled?).and_return(true)
              expect(permit.user_can_access_live_chat?).to be_truthy
            end
          end

          context 'when live chat is disabled for the current course' do
            it 'returns false' do
              allow(permit).to receive(:live_chat_enabled?).and_return(false)
              expect(permit.user_can_access_live_chat?).to be_falsey
            end
          end
        end
      end
    end

    describe '#live_chat_enabled?' do
      let(:user) { build_stubbed(:user) }

      describe 'when section is nil' do
        let(:permit) { Permission.new(user, program, access_guardian, nil) }

        it 'returns false' do
          expect(permit.live_chat_enabled?).to be_falsey
        end
      end

      describe 'when section is section zero' do
        let(:permit) { Permission.new(user, program, access_guardian, Section.section_zero) }

        it 'returns false' do
          expect(permit.live_chat_enabled?).to be_falsey
        end
      end

      describe 'when the current course has live chat disabled' do
        it 'returns false' do
          course = build_stubbed(:course)
          section = build_stubbed(:section, :course => course)
          allow(course).to receive(:live_chat_enabled?).and_return(false)
          permit = Permission.new(user, program, access_guardian, section)
          expect(permit.live_chat_enabled?).to be_falsey
        end
      end

      describe 'when the current course has live chat enabled' do
        it 'returns true' do
          course = build_stubbed(:course)
          section = build_stubbed(:section, :course => course)
          allow(course).to receive(:live_chat_enabled?).and_return(true)
          permit = Permission.new(user, program, access_guardian, section)
          expect(permit.live_chat_enabled?).to be_truthy
        end
      end
    end

    describe '#partner_chat_enabled?' do
      let(:user) { build_stubbed(:user) }

      context 'when section is nil' do
        let(:permit) { Permission.new(user, program, access_guardian, nil) }

        it 'returns false' do
          expect(permit.partner_chat_enabled?).to be_falsey
        end
      end

      context 'when section is section zero' do
        let(:permit) { Permission.new(user, program, access_guardian, Section.section_zero) }

        it 'returns false' do
          expect(permit.partner_chat_enabled?).to be_falsey
        end
      end

      context 'when the current course has live chat disabled' do
        it 'returns false' do
          course = build_stubbed(:course)
          section = build_stubbed(:section, :course => course)
          allow(course).to receive(:partner_chat_enabled?).and_return(false)
          permit = Permission.new(user, program, access_guardian, section)
          expect(permit.partner_chat_enabled?).to be_falsey
        end
      end

      context 'when the current course has partner chat enabled' do
        it 'returns true' do
          course = build_stubbed(:course)
          section = build_stubbed(:section, :course => course)
          allow(course).to receive(:partner_chat_enabled?).and_return(true)
          permit = Permission.new(user, program, access_guardian, section)
          expect(permit.partner_chat_enabled?).to be_truthy
        end
      end

      context 'when the current course has live chat enabled' do
        it 'returns true' do
          course = build_stubbed(:course)
          section = build_stubbed(:section, :course => course)
          allow(course).to receive(:live_chat_enabled?).and_return(true)
          permit = Permission.new(user, program, access_guardian, section)
          expect(permit.partner_chat_enabled?).to be_truthy
        end
      end
    end

    describe '#chat_course_id' do
      context 'when the current user is an instructor' do
        it 'returns nil' do
          instructor = build_stubbed(:instructor)
          section = build_stubbed(:section_with_course)
          permit = described_class.new(instructor, program, access_guardian, section)
          expect(permit.chat_course_id).to eq(nil)
        end
      end

      context 'when the current user is a student' do
        it 'returns the course id for the current section' do
          student = build_stubbed(:student)
          section = build_stubbed(:section_with_course)
          permit = described_class.new(student, program, access_guardian, section)
          expect(permit.chat_course_id).to eq(section.course_id)
        end
      end
    end

    describe '#chat_section_id' do
      context 'when the current user is an instructor' do
        it 'returns 0' do
          instructor = build_stubbed(:instructor)
          section = build_stubbed(:section_with_course)
          permit = described_class.new(instructor, program, access_guardian, section)
          expect(permit.chat_section_id).to eq(0)
        end
      end

      context 'when the current user is a student' do
        it 'returns the course id for the current section' do
          student = build_stubbed(:student)
          section = build_stubbed(:section)
          permit = described_class.new(student, program, access_guardian, section)
          expect(permit.chat_section_id).to eq(section.id)
        end
      end
    end

    describe '#chat_permissions' do
      context 'when the current user is an instructor,' do
        let(:instructor) { build_stubbed(:instructor) }
        let(:permit) { described_class.new(instructor, program, access_guardian, section) }

        it 'returns false for live chat and partner chat for a SS Jr program' do
          allow(program).to receive(:supersite_junior?).and_return(true)

          expect(JSON.parse(permit.chat_permissions, symbolize_names: true)).to eq(
            live_chat_enabled: false, partner_chat_enabled: false
          )
        end

        it 'returns true for partner chat and live chat for a non SS JR program' do
          allow(program).to receive(:supersite_junior?).and_return(false)

          expect(JSON.parse(permit.chat_permissions, symbolize_names: true)).to eq(
            live_chat_enabled: true, partner_chat_enabled: true
          )
        end
      end

      context 'when the current user is a student,' do
        let(:student) { build_stubbed(:student) }
        let(:permit) { described_class.new(student, program, access_guardian, section) }
        let(:course) { instance_double(Course) }

        before do
          allow(section).to receive(:course).and_return(course)
        end

        it 'returns false for live chat and partner chat for a SS Jr program' do
          allow(program).to receive(:supersite_junior?).and_return(true)

          expect(JSON.parse(permit.chat_permissions, symbolize_names: true)).to eq(
            live_chat_enabled: false, partner_chat_enabled: false
          )
        end

        it "returns the chat permissions for the student's course for a " \
           'non SS Jr program' do
          allow(program).to receive(:supersite_junior?).and_return(false)

          allow(course).to receive(:live_chat_enabled?).and_return(false)
          allow(course).to receive(:partner_chat_enabled?).and_return(true)

          expect(JSON.parse(permit.chat_permissions, symbolize_names: true)).to eq(
            live_chat_enabled: false, partner_chat_enabled: true
          )
        end
      end
    end
  end
end
