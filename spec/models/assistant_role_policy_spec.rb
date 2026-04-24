describe AssistantRolePolicy do
  let(:current_user) { create(:instructor) }

  describe "#is_instructor?" do
    it 'returns true when section instructor has the instructor role' do
      section_instructor = create(:section_instructor, instructor: current_user, role: 'Instructor')
      current_focus = double(Focus, sections: [])
      role_policy = described_class.new(current_focus, current_user)
      expect(role_policy.is_instructor?(section_instructor.section_id)).to eq(true)
    end

    it 'returns false when section instructor does not have the instructor role' do
      section_instructor = create(:section_instructor, instructor: current_user, role: 'Assistant')
      current_focus = double(Focus, sections: [])
      role_policy = described_class.new(current_focus, current_user)
      expect(role_policy.is_instructor?(section_instructor.section_id)).to eq(false)
    end
  end

  describe '#is_instructor_or_co_instructor?' do
    it 'returns true when section instructor has the instructor role' do
      section_instructor = create(:section_instructor, instructor: current_user, role: 'Instructor')
      current_focus = double(Focus, sections: [])
      role_policy = described_class.new(current_focus, current_user)
      expect(role_policy.is_instructor_or_co_instructor?(section_instructor.section_id)).to eq(true)
    end

    it 'returns true when section instructor has the co-instructor role' do
      section_instructor = create(:section_instructor, instructor: current_user, role: 'Co-instructor')
      current_focus = double(Focus, sections: [])
      role_policy = described_class.new(current_focus, current_user)
      expect(role_policy.is_instructor_or_co_instructor?(section_instructor.section_id)).to eq(true)
    end

    it 'returns false when section instructor does not have neither instructor role or co-instructor role' do
      section_instructor = create(:section_instructor, instructor: current_user, role: 'Assistant')
      current_focus = double(Focus, sections: [])
      role_policy = described_class.new(current_focus, current_user)
      expect(role_policy.is_instructor_or_co_instructor?(section_instructor.section_id)).to eq(false)
    end
  end

  describe '#is_assistant?' do
    context 'when current_focus has one section' do
      it 'returns true when section_instructor has the Assistant role' do
        section_instructor = create(:section_instructor, instructor: current_user, role: 'Assistant')
        section = create(:section, section_instructors: [section_instructor])
        current_focus = double(Focus, sections: [section])
        expect(AssistantRolePolicy.new(current_focus, current_user).is_assistant?).to be_truthy
      end

      it 'returns false when section_instructor has the Instructor role' do
        section_instructor = create(:section_instructor, instructor: current_user, role: 'Instructor')
        section = create(:section, section_instructors: [section_instructor])
        current_focus = double(Focus, sections: [section])
        expect(AssistantRolePolicy.new(current_focus, current_user).is_assistant?).not_to be_truthy
      end

      it 'returns false when section_instructor has the Co-Instructor role' do
        section_instructor = create(:section_instructor, instructor: current_user, role: 'Co-Instructor')
        section = create(:section, section_instructors: [section_instructor])
        current_focus = double(Focus, sections: [section])
        expect(AssistantRolePolicy.new(current_focus, current_user).is_assistant?).not_to be_truthy
      end


      it 'returns false when section_instructor has an assistant record, but for a different user' do
        another_user = create(:instructor)
        section_instructor = create(:section_instructor, instructor: another_user, role: 'Assistant')
        section = create(:section, section_instructors: [section_instructor])
        current_focus = double(Focus, sections: [section])
        expect(AssistantRolePolicy.new(current_focus, current_user).is_assistant?).not_to be_truthy
      end

      it 'returns false when section_instructor has no records for the current_user' do
        another_user = create(:instructor)
        section_instructor = create(:section_instructor, instructor: another_user)
        section = create(:section, section_instructors: [section_instructor])
        current_focus = double(Focus, sections: [section])
        expect(AssistantRolePolicy.new(current_focus, current_user).is_assistant?).not_to be_truthy
      end

    end

    context 'when current focus sections is nil' do
      let(:current_focus) { double(Focus, sections: nil) }
      it 'returns false' do
        expect(AssistantRolePolicy.new(current_focus, current_user).is_assistant?).not_to be_truthy
      end
    end

    context 'when current focus sections is empty' do
      let(:current_focus) { double(Focus, sections: []) }
      it 'returns false' do
        expect(AssistantRolePolicy.new(current_focus, current_user).is_assistant?).not_to be_truthy
      end
    end

    context 'when current_focus has multiple sections' do

      it 'returns true when section_instructors has one record for each section, one assistant, the other instructor' do
        section_instructor = create(:section_instructor, instructor: current_user, role: 'Assistant')
        other_section_instructor = create(:section_instructor, instructor: current_user, role: 'Instructor')
        section = create(:section, section_instructors: [section_instructor, other_section_instructor])
        current_focus = double(Focus, sections: [section])
        expect(AssistantRolePolicy.new(current_focus, current_user).is_assistant?).to be_truthy
      end

      it 'returns false when section_instructors has a record for one section, but not for the other section' do
        section_instructor = create(:section_instructor, instructor: current_user, role: 'Assistant')
        other_section_instructor = create(:section_instructor)
        section = create(:section, section_instructors: [section_instructor, other_section_instructor])
        current_focus = double(Focus, sections: [section])
        expect(AssistantRolePolicy.new(current_focus, current_user).is_assistant?).to be_truthy
      end

    end

  end

end
