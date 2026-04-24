#encoding: utf-8
describe ResourceRefinements do

  describe "#refinements_description" do

    let(:finder)    { double('resource_finder', :grouped_by_file_type => [], :grouped_by_source => [], :grouped_by_unit_type => [], :grouped_by_component => []) }
    let(:program) { build_stubbed(:program) }

    context "without filters" do
      it "should return 'Browse Resources'" do
        resource_refinements = ResourceRefinements.new(finder, program)
        expect(resource_refinements.refinements_description).to eq("Browse Resources")
      end
    end

    context 'with single filter' do
      it 'should show description for unit filter' do
        unit = create(:unit, label: 'Paginas 1')
        resource_refinements = ResourceRefinements.new(finder,
                                                       program,
                                                       { start_unit_id: unit.id })
        expect(resource_refinements.refinements_description)
          .to eq "Paginas 1 | All Components"
      end

      it "should show description for component filter" do
        component = create(:resource_component)
        resource_refinements = ResourceRefinements.new(finder, program, :component_id => component.id)
        expect(resource_refinements.refinements_description).to eq(component.name)
      end

      it 'should show description for lesson filter when lesson has a label' do
        lesson = create(:lesson, label: 'Leçon 1A', name: 'Leçon 1A | Mon dieu')
        resource_refinements = ResourceRefinements.new(finder,
                                                       program,
                                                       { lesson_id: lesson.id})
        expect(resource_refinements.refinements_description)
          .to eq "Leçon 1A | All Components"
      end

      it 'should show description for lesson filter when lesson does not have a label' do
        lesson = create(:lesson, label: '', name: 'Leçon 1A | Mon dieu')
        resource_refinements = ResourceRefinements.new(finder,
                                                       program,
                                                       { lesson_id: lesson.id})
        expect(resource_refinements.refinements_description)
          .to eq "Leçon 1A | Mon dieu | All Components"
      end

      context 'with multi-lesson filter' do
        it 'displays the word Multi-<unit-label>' do
          allow(program).to receive(:unit_label).and_return('SuperUnit')
          resource_refinements = ResourceRefinements.new(finder,
                                                         program,
                                                         start_unit_id: [1, 2])
          expect(resource_refinements.refinements_description)
            .to eq 'Multi-superunit | All Components'
        end
      end
    end

    context "with more than one filter" do
      it "should show description for all filters" do
        unit = create(:unit, :label => 'Paginas 1')
        lesson = create(:lesson, :label => 'Leçon 1A')
        component = create(:resource_component, :name => 'Activity Pack')
        resource_refinements = ResourceRefinements.new(finder, program, :start_unit_id => unit.id, :component_id => component.id, :lesson_id => lesson.id)
        expect(resource_refinements.refinements_description).to eq("Paginas 1 | Leçon 1A | Activity Pack")
      end
    end

  end

  describe 'resource filters' do
    let(:program)   { build_stubbed(:program) }
    let(:component) { build_stubbed(:resource_component, :name => 'foo') }
    let(:unit)      { create(:unit, :program => program) }
    let(:lesson)    { create(:lesson) }
    let!(:resource) { build_stubbed(:resource, :unit => unit, :resource_component => component, :lesson => lesson) }
    let(:finder)    { double('resource_finder', :grouped_by_file_type => [], :grouped_by_source => [], :grouped_by_unit_type => [], :grouped_by_component => []) }

    context "when filtering by component" do

      it 'returns the options for the resource components' do
        allow(resource).to receive(:resource_component_count).and_return(2)
        allow(finder).to receive(:grouped_by_component).and_return([resource])

        resource_refinements = ResourceRefinements.new(finder, program)
        options = resource_refinements.category_options('components')
        key = component.name
        expect(options[key][:count]).to eq(2)
        expect(options[key][:link_params]).to eq("?component_id=#{component.id}")
        expect(options[key][:display_name]).to eq(key)
        expect(options[key][:show_link]).to be_truthy
      end

      context 'given a matching component_id as a param' do
        it 'does not show a link' do
          allow(resource).to receive(:resource_component_count).and_return(2)
          allow(finder).to receive(:grouped_by_component).and_return([resource])

          resource_refinements = ResourceRefinements.new(finder, program, :component_id => component.id)
          options = resource_refinements.category_options('components')
          expect(options[component.name][:show_link]).to be_falsey
        end
      end
    end

    context 'when filtering by unit' do

      context "when none of the resources is associated with a unit" do
        it "returns only a category with title 'not applicable'" do
          resource_refinements = ResourceRefinements.new(finder, program)

          category_options = resource_refinements.category_options('units')
          expect(category_options.size).to eq(1)
          expect(category_options[0][:count]).to eq('')
          expect(category_options[0][:display_name]).to eq('not applicable')
          expect(category_options[0][:show_link]).to be_falsey
        end
      end

      context 'when the resource is not multi-unit' do
        it 'returns the options for units' do
          allow(resource).to receive(:resource_unit_count).and_return(2)
          allow(finder).to receive(:grouped_by_unit_type).and_return([resource])

          resource_refinements = ResourceRefinements.new(finder, program)
          options = resource_refinements.category_options('units')
          key = unit.rank
          expect(options[key][:count]).to eq(2)
          expect(options[key][:link_params]).to eq("?start_unit_id=#{unit.id}")
          expect(options[key][:display_name]).to eq(unit.display_name)
          expect(options[key][:show_link]).to be_truthy
        end

        describe "with can_see_unreleased_units as false" do
          context "when resource is for a non released unit" do
            let(:unreleased_unit) { create(:unit, :released => false, :rank => 43) }
            let(:resource_of_unreleased_unit) { build_stubbed(:resource, :unit => unreleased_unit, :resource_component => component, :lesson => lesson) }

            it "it doesn't include the unreleased unit in the refinement options" do
              expect(program).to receive(:visible_units_and_resource_units).with(false).and_return([unit])
              allow(resource).to receive(:resource_unit_count).and_return(2)
              allow(resource_of_unreleased_unit).to receive(:resource_unit_count).and_return(2)
              allow(finder).to receive(:grouped_by_unit_type).and_return([resource, resource_of_unreleased_unit])

              resource_refinements = ResourceRefinements.new(finder, program, { :can_see_unreleased_units => false })
              options = resource_refinements.category_options('units')
              expect(options[unit.rank]).to be_present
              expect(options[unreleased_unit.rank]).to be_blank
            end
          end
        end

        describe "with can_see_unreleased_units as true" do
          context "when resource is for a non released unit" do
            let(:unreleased_unit) { create(:unit, :released => false, :rank => 43) }
            let(:resource_of_unreleased_unit) { build_stubbed(:resource, :unit => unreleased_unit, :resource_component => component, :lesson => lesson) }

            it "it includes the unreleased unit in the refinement options" do
              expect(program).to receive(:visible_units_and_resource_units).with(true).and_return([unit, unreleased_unit])
              allow(resource).to receive(:resource_unit_count).and_return(2)
              allow(resource_of_unreleased_unit).to receive(:resource_unit_count).and_return(2)
              allow(finder).to receive(:grouped_by_unit_type).and_return([resource, resource_of_unreleased_unit])

              resource_refinements = ResourceRefinements.new(finder, program, { :can_see_unreleased_units => true })
              options = resource_refinements.category_options('units')
              expect(options[unit.rank]).to be_present
              expect(options[unreleased_unit.rank]).to be_present
            end
          end
        end

        context 'given a matching unit id as a param' do
          it 'does not show a link' do
            allow(resource).to receive(:resource_unit_count).and_return(2)
            allow(finder).to receive(:grouped_by_unit_type).and_return([resource])

            resource_refinements = ResourceRefinements.new(finder, program, :start_unit_id => unit.id)
            options = resource_refinements.category_options('units')
            expect(options[unit.rank][:show_link]).to be_falsey
          end
        end
      end

      context 'when resource is multi-unit' do
        it 'returns multi-unit options' do
          resource.start_unit_id = 1
          resource.end_unit_id = 2
          allow(finder).to receive(:grouped_by_unit_type).and_return([resource])

          resource_refinements = ResourceRefinements.new(finder, program)
          options = resource_refinements.category_options('units')
          key = ResourceRefinements::MULTI_UNIT_RANK
          expect(options[key][:count]).to eq(1)
          expect(options[key][:link_params]).to eq("?start_unit_id[]=#{program.units_and_resource_units.map(&:id).first}")
          expect(options[key][:display_name]).to eq(program.multi_unit_resource_label)
          expect(options[key][:show_link]).to be_truthy
        end

        context 'when multiple units are passed as params' do
          it 'does not render a link' do
            resource.start_unit_id = 1
            resource.end_unit_id = 2
            allow(finder).to receive(:grouped_by_unit_type).and_return([resource])

            resource_refinements = ResourceRefinements.new(finder, program, :start_unit_id => [1, 2])
            options = resource_refinements.category_options('units')
            key = ResourceRefinements::MULTI_UNIT_RANK
            expect(options[key][:show_link]).to be_falsey
          end
        end
      end
    end

    context 'when filtering by lesson' do
      it 'returns lesson options' do
        allow(program).to receive(:two_tier?).and_return(true)
        allow(resource).to receive(:resource_lesson_count).and_return(2)
        allow(finder).to receive(:grouped_by_lesson).and_return([resource])

        resource_refinements = ResourceRefinements.new(finder, program)
        options = resource_refinements.category_options('lessons')
        key = resource.lesson_id
        expect(options[key][:count]).to eq(2)
        expect(options[key][:link_params]).to eq("?lesson_id=#{key}")
        expect(options[key][:display_name]).to eq(lesson.name)
        expect(options[key][:show_link]).to be_truthy
      end
    end
  end
end
