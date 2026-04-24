describe ResourceHelper do
  include ResourceHelper

  describe '#resource_index_link' do
    let(:program) { build_stubbed(:program) }
    let(:section) { build_stubbed(:section) }

    before do
      allow(helper).to receive(:current_program).and_return(program)
      allow(helper).to receive(:current_section_id).and_return(section.id)
    end

    it 'returns the Supersite Jr. route including the current program, the ' \
       'current section id, and any specified path args when the current ' \
       'program is Supersite Jr.' do
      allow(helper).to receive(:supersite_junior?).and_return(true)

      expect(helper.resource_index_link(start_unit_id: 1)).to eq(
        jr_resources_path(
          program_id: program.id, section_id: section.id, start_unit_id: 1
        )
      )
    end

    it 'returns the non-Supersite Jr. route including the current program and ' \
       'any specified path args when the current program is not Supersite Jr.' do
      allow(helper).to receive(:supersite_junior?).and_return(false)

      expect(helper.resource_index_link(start_unit_id: 1)).to eq(
        instructor_program_resources_path(
          program_id: program.id, start_unit_id: 1
        )
      )
    end
  end

  describe '#error_message_for_protected_resources' do
    context 'when protected resources are given' do
      before(:each) do
        protected_resource = build_stubbed(:resource, :protected => true, :title => 'protected_resource')
        @error_message = error_message_for_protected_resources([protected_resource])
      end
      it 'returns a message header' do
        expect(@error_message).to include 'Your changes were saved except for the following resource(s), which can never be shown to students:'
      end
      it 'returns protected resource title' do
        expect(@error_message).to include 'protected_resource'
      end
    end

    context 'when protected resources are not given' do
      before(:each) do
        protected_resource = build_stubbed(:resource, :protected => false, :title => 'protected_resource')
        @error_message = error_message_for_protected_resources([protected_resource])
      end
      it 'returns an empty string' do
        expect(@error_message).to be_empty
      end

    end
  end

  describe '#file_type' do
    it 'returns PDF when input parameter is .pdf' do
      file_extension = ".pdf"
      expected_output = "PDF"
      expect(file_type(file_extension)).to eql expected_output
    end

    it 'returns Document when input parameter is an text file extension' do
      file_extension_1 = ".doc"
      file_extension_2 = ".rtf"
      expected_output = "Document"
      expect(file_type(file_extension_1)).to eql expected_output
      expect(file_type(file_extension_2)).to eql expected_output
    end

    it 'returns Image when input parameter is an image file extension' do
      file_extension_1 = ".jpg"
      file_extension_2 = ".gif"
      file_extension_3 = ".png"
      expected_output = "Image"
      expect(file_type(file_extension_1)).to eql expected_output
      expect(file_type(file_extension_2)).to eql expected_output
      expect(file_type(file_extension_3)).to eql expected_output
    end

    it 'returns Presentation when input parameter is .ppt' do
      file_extension = ".ppt"
      expected_output = "Presentation"
      expect(file_type(file_extension)).to eql expected_output
    end

    it 'returns Audio when input parameter is .mp3' do
      file_extension = ".mp3"
      expected_output = "Audio"
      expect(file_type(file_extension)).to eql expected_output
    end

    it 'returns Other when input parameter is not recognized' do
      file_extension = "other_extension"
      expected_output = "Other"
      expect(file_type(file_extension)).to eql expected_output
    end
  end

  describe '#formatted_resource_component_list' do
    it 'returns the name of the components without html tags' do
      resource_component_list = [build_stubbed(:resource_component, :name => "<b>test component</b>")]
      formated_components = formatted_resource_component_list(resource_component_list)
      expect(formated_components.first).to include "test component"
    end
  end

  describe '#units_filter_options' do
    let(:program_with_units) { create(:program_with_lessons_and_resource_units) }
    let(:current_program) { program_with_units }
    let(:supersite_junior?) { program_with_units.supersite_junior? }
    let(:expected_select_options) do
      program_with_units.units.map do |unit|
        [
          unit.resources_form_display_name,
          "/resources/programs/#{program_with_units.id}?start_unit_id=#{unit.id}",
          { lang: program_with_units.language_code }
        ]
      end
    end

    it 'returns the unit resources display name and route in the options' do
      expect(units_filter_options(program_with_units.units)).to match expected_select_options
    end

    it 'returns a General Resources option if there is a unit named No Lesson' do
      unit = program_with_units.units.first
      unit.update(name: 'No Lesson')
      expected_option = [
        'General Resources',
        "/resources/programs/#{program_with_units.id}?start_unit_id=#{unit.id}",
        { lang: program_with_units.language_code }
      ]
      expect(units_filter_options(program_with_units.units)[0]).to eq expected_option
    end

    it 'returns a General Resources option if there is a unit named No Unit' do
      unit = program_with_units.units.first
      unit.update(name: 'No Unit')
      expected_option = [
        'General Resources',
        "/resources/programs/#{program_with_units.id}?start_unit_id=#{unit.id}",
        { lang: program_with_units.language_code }
      ]
      expect(units_filter_options(program_with_units.units)[0]).to eq expected_option
    end

    context 'when a program is two tier' do
      let(:program_with_units) { create(:two_tier_program_with_unit_in_lesson_names) }
      let(:expected_select_options) do
        program_with_units.units.each_with_object([]) do |unit, options|
          options << [
            unit.resources_form_display_name,
            "/resources/programs/#{program_with_units.id}?start_unit_id=#{unit.id}",
            { lang: program_with_units.language_code }
          ]
          unit.lessons.each do |lesson|
            options << [
              lesson.name,
              "/resources/programs/#{program_with_units.id}?lesson_id=#{lesson.id}&start_unit_id=#{unit.id}",
              { class: 'c-lesson-selector__lesson' }
            ]
          end
        end
      end

      it 'includes the lessons in the returned options for select' do
        expect(units_filter_options(program_with_units.units)).to match expected_select_options
      end
    end
  end
end
