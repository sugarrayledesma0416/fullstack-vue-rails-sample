describe Unit do

  RSpec.shared_examples 'display name tests' do |method_to_test|
    let(:unit) { build_stubbed(:unit) }

    it 'returns label if label valid label exists' do
      unit.label = 'Label'
      expect(unit.public_send(method_to_test)).to eql('Label')
    end

    it 'returns name if label is nil' do
      unit.label = nil
      expect(unit.public_send(method_to_test)).to eql('Lesson 1')
    end

    it 'returns name if label is blank' do
      unit.label = ' '
      expect(unit.public_send(method_to_test)).to eql('Lesson 1')
    end
  end

  describe "scopes" do
    describe ".released" do
      it "returns only the released units" do
        released_unit = create(:unit, :released => true)
        unreleased_unit = create(:unit, :released => false)
        units_results = Unit.released
        expect(units_results).to include released_unit
        expect(units_results).not_to include unreleased_unit
      end
    end

    describe ".in_rank_range" do
      let(:program) { create(:program) }
      let(:first_unit) { create(:unit, :rank => 1, :program => program) }
      let(:second_unit) { create(:unit, :rank => 2, :program => program) }
      let(:third_unit) { create(:unit, :rank => 3, :program => program) }

      before do
        program.units << first_unit
        program.units << second_unit
        program.units << third_unit
      end

      it "returns only the units for the given range" do
        result_units = program.units.in_rank_range(2, 3)
        expect(result_units).to include second_unit
        expect(result_units).to include third_unit
        expect(result_units).not_to include first_unit
      end
    end

    describe '.by_program' do
      it 'returns only the units for the given program' do
        program = create(:program)
        target_unit = create(:unit, :program => program)
        other_program_unit = create(:unit, :program => create(:program))
        expect(Unit.by_program(program)).to match_array([target_unit])
      end
    end

    describe '.resource_only' do
      it 'returns only the units with the use_type of ResourceUnit' do
        resource_unit = create(:unit, :use_type => 'ResourceUnit')
        non_resource_unit = create(:unit)
        expect(Unit.resource_only).to match_array([resource_unit])
      end
    end

    describe '.by_activity' do
      it 'returns the unit associated with the specified activity id' do
        unit = create(:unit)
        other_unit = create(:unit)
        lesson = create(:lesson, :unit => unit)
        other_lesson = create(:lesson, :unit => other_unit)
        activity = create(:activity, :lesson => lesson)
        create(:activity, :lesson => other_lesson)
        expect(Unit.by_activity(activity)).to eq([unit])
      end
    end

  end

  describe '#display_name' do
    include_examples 'display name tests', 'display_name'
  end

  describe '#resources_form_display_name' do
    include_examples 'display name tests', 'resources_form_display_name'

    it 'returns resources_form_title if it is set' do
      expected_title = 'Unit Resources Title'
      unit = build_stubbed(:unit, resources_form_title: expected_title)
      expect(unit.resources_form_display_name).to eq expected_title
    end
  end

  describe '#resource_only_unit_for_program' do
    it 'returns a ResourceUnit for the specified program' do
      program = create(:program)
      target_unit = create(:unit, :program => program, :use_type => 'ResourceUnit')
      non_resource_unit = create(:unit, :program => program)
      other_program_unit = create(:unit, :program => create(:program),  :use_type => 'ResourceUnit')
      expect(Unit.resource_only_unit_for_program(program)).to eq(target_unit)
    end
  end

end
