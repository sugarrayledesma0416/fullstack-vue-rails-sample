describe ResourcesPresenter do
  let(:user)      { build_stubbed(:instructor) }
  let(:program)   { build_stubbed(:program) }
  let(:section)   { build_stubbed(:section) }
  let(:options)   { {} }
  let(:presenter) { described_class.new(user, section, program, options) }

  describe '#program_unit_label' do
    context 'when program has no unit label' do
      it 'returns "Unit"' do
        allow(program).to receive(:unit_label).and_return('')
        expect(presenter.program_unit_label).to eq 'Unit'
      end
    end

    context 'when program has unit label' do
      it 'returns the value set fot unit label' do
        expect(presenter.program_unit_label).to eq program.unit_label
      end
    end
  end

  describe '#resource_status_for' do
    let(:resource_1) { build_stubbed(:resource, protected: false) }

    context 'when the resource is protected' do
      before { resource_1.protected = true }

      it "returns 'protected'" do
        expect(presenter.resource_status_for(resource_1)).to eql('protected')
      end
    end

    context 'when the user is resource editor' do
      before { allow(user).to receive(:is_resource_editor?).and_return(true) }

      context 'when vhl_student_resource is true' do
        before { resource_1.vhl_student_resource = true }

        it "returns 'shown'" do
          expect(presenter.resource_status_for(resource_1)).to eql('shown')
        end
      end

      context 'when vhl_student_resource is false' do
        before { resource_1.vhl_student_resource = true }

        it "returns 'hidden'" do
          expect(presenter.resource_status_for(resource_1)).to eql('shown')
        end
      end
    end

    context 'when the user is not resource editor' do
      context 'when there are not resource settings' do
        before do
          allow(presenter).to receive(:instructor_resource_settings).and_return([])
        end

        it "returns 'hidden'" do
          expect(presenter.resource_status_for(resource_1)).to eql('hidden')
        end
      end

      context 'when resource has multiple settings' do
        let(:another_user) { build_stubbed(:instructor) }
        let(:instructor_resource_setting_1) do
          build_stubbed(
            :instructor_resource_setting,
            instructor: user,
            resource_id: resource_1.id,
            student_visibility: 'shown'
          )
        end
        let(:instructor_resource_setting_2) do
          build_stubbed(
            :instructor_resource_setting,
            instructor: another_user,
            resource_id: resource_1.id,
            student_visibility: 'hidden'
          )
        end

        before do
          allow(presenter).to receive(:instructor_resource_settings)
            .and_return([instructor_resource_setting_1, instructor_resource_setting_2])
        end

        it 'returns setting value for the current user' do
          expect(presenter.resource_status_for(resource_1)).to eql('shown')
        end
      end
    end
  end

  describe '#lessons' do
    let(:expected_lessons) { double('Lesson') }

    context 'with a non two-tier program' do
      before do
        allow(program).to receive(:two_tier?).and_return(false)
      end

      it 'returns nil' do
        expect(presenter.lessons).to be_nil
      end
    end

    context 'with a two-tier program' do
      before do
        allow(program).to receive(:two_tier?).and_return(true)
      end

      context 'when user cannot see unreleased units' do
        it 'retrieves the lessons from released units' do
          allow(user).to receive(:can_view_unreleased_units?).and_return(false)
          allow(program).to receive(:visible_lessons).with(false).and_return(expected_lessons)
          expect(presenter.lessons).to eql expected_lessons
        end
      end

      context 'when user can see unreleased units' do
        it 'retrieves the lessons from released and unreleased units' do
          allow(user).to receive(:can_view_unreleased_units?).and_return(true)
          allow(program).to receive(:visible_lessons).with(true).and_return(expected_lessons)
          expect(presenter.lessons).to eql expected_lessons
        end
      end
    end
  end

  describe '#units' do
    let(:expected_units) { [double('Unit', id: 1)] }

    context 'when user cannot see unreleased units' do
      it 'retrieves the released units' do
        allow(user).to receive(:can_view_unreleased_units?).and_return(false)
        allow(program).to receive(:visible_units_and_resource_units).with(false).and_return(expected_units)
        expect(presenter.units).to eql expected_units
      end
    end

    context 'when user can see unreleased units' do
      it 'retrieves the released and unreleased units' do
        allow(user).to receive(:can_view_unreleased_units?).and_return(true)
        allow(program).to receive(:visible_units_and_resource_units).with(true).and_return(expected_units)
        expect(presenter.units).to eql expected_units
      end
    end
  end

  describe '#components' do
    let(:component_not_for_student) do
      create(:resource_component, name: 'Not For Students', program: program)
    end
    let(:component_for_student) do
      create(:resource_component, name: 'Lab Videos', program: program)
    end
    let!(:resource_not_for_student) do
      create(
        :resource,
        program: program,
        resource_component: component_not_for_student,
        vhl_student_resource: false
      )
    end
    let!(:resource_for_student) do
      create(
        :resource,
        program: program,
        resource_component: component_for_student,
        vhl_student_resource: true
      )
    end

    context 'when as an instructor' do
      let(:user) { create(:instructor) }

      it 'returns the resource components for the whole program' do
        results = presenter.components
        expect(results).to include component_not_for_student
        expect(results).to include component_for_student
      end
    end

    context 'when as a student' do
      let(:user) { create(:student) }

      it 'returns all the components for the resources the student can access' do
        results = presenter.components
        expect(results).not_to include component_not_for_student
        expect(results).to include component_for_student
      end
    end
  end

  describe '#unit_title' do
    let(:program) { create(:program) }
    let(:unit_1) { create(:unit, program:) }

    let(:resource) { create(:resource, start_unit_id: unit_1.id, program:) }

    it 'returns resources_form_title field if it is defined' do
      unit_1.update!(resources_form_title: 'Unit 1', name: 'Unit 1 Going Shopping', label: 'Lesson 1')

      expect(presenter.unit_title(unit_1, resource)).to eql('Unit 1')
    end

    it 'returns name field if it is defined and resources_form_title is null' do
      unit_1.update!(resources_form_title: nil, name: 'Unit 1 Going Shopping', label: nil)

      expect(presenter.unit_title(unit_1, resource)).to eql('Unit 1 Going Shopping')
    end

    it 'returns label field if resources_form_title and name are not defined' do
      unit_1.update!(resources_form_title: nil, name: nil, label: 'Lesson 1')

      expect(presenter.unit_title(unit_1, resource)).to eql('Lesson 1')
    end
  end

  describe '#has_units_with_blank_label?' do
    let(:program) { create(:program) }
    let(:unit_1) { create(:unit, program:) }
    let(:unit_2) { create(:unit, program:) }

    let(:resource) { create(:resource, start_unit_id: unit_1.id, program:) }

    it 'is false if all units have a non-blank label' do
      unit_1.update!(label: 'Lesson 1')
      unit_2.update!(label: 'Lesson 2')

      expect(presenter).not_to have_units_with_blank_label(resource)
    end

    it 'is true if some unit labels are non-blank and others are null' do
      unit_1.update!(label: 'Lesson 1')
      unit_2.update!(label: nil)

      expect(presenter).to have_units_with_blank_label(resource)
    end

    it 'is true if some unit labels are not blank and some are an empty string' do
      unit_1.update!(label: 'Lesson 1')
      unit_2.update!(label: '')

      expect(presenter).to have_units_with_blank_label(resource)
    end

    it 'is true if all unit labels are either blank or null' do
      unit_1.update!(label: nil)
      unit_2.update!(label: '')

      expect(presenter).to have_units_with_blank_label(resource)
    end
  end
end
