describe TeacherVtextLinker do
  let(:activity) { create(:activity, :page => '2-5') }
  let(:program) { FactoryBot.build_stubbed(:program, family: 'vista_online_learning') }
  let!(:program_settings) { double(ProgramSettings) }
  let(:user) { create(:instructor) }

  before do
    allow(ProgramSettings).to receive(:new).and_return(program_settings)
  end

  describe '#link_label' do
    it 'returns the overriden configuration for the teacher vtext label if present' do
      expect(program_settings).to receive(:teacher_vtext_label)
        .and_return("professor's guideline").at_least(2)

      vtext_linker = described_class.new(program, user, activity)

      expect(vtext_linker.link_label).to eq "professor's guideline"
    end

    context 'when the vtext teacher label has not been overriden' do
      before do
        allow(program_settings).to receive(:teacher_vtext_label)
      end

      it 'returns teacher edition link label' do
        program = build(:program)
        vtext_linker = described_class.new(program, user, activity)

        expect(vtext_linker.link_label).to eq "Teacher's Edition"
      end

      it 'returns instructor manual when program is vista online learning' do
        program = build(:program, family: 'vista_online_learning')
        vtext_linker = described_class.new(program, user, activity)

        expect(vtext_linker.link_label).to eq "Instructor's Manual"
      end
    end
  end

  describe 'menu_linkable?' do
    context 'when user is instructor' do
      context 'when program has vtext' do
        it 'returns true' do
          allow(program_settings).to receive(:has_teacher_vtext_link?).and_return(true)
          vtext_linker = TeacherVtextLinker.new(program, user, activity)
          expect(vtext_linker).to be_menu_linkable
        end
      end

      context 'when program does not have vtext' do
        it 'returns false' do
          allow(program_settings).to receive(:has_teacher_vtext_link?).and_return(false)
          vtext_linker = TeacherVtextLinker.new(program, user, activity)
          expect(vtext_linker).not_to be_menu_linkable
        end
      end
    end

    context 'when user is not instructor' do
      it 'returns false' do
        allow(user).to receive(:instructor?).and_return(false)
        vtext_linker = TeacherVtextLinker.new(program, user, activity)
        expect(vtext_linker).not_to be_menu_linkable
      end
    end
  end
end
