describe Resource do
  let(:program) { create(:program_with_lessons) }
  let(:lesson) { create(:lesson_with_unit, unit_id: program.units.first.id) }
  let(:resource_component) { create(:resource_component, program: program) }

  let(:component_1_non_student_resource)   do
    create(:resource, start_unit_id: program.units.first.id, lesson_id: lesson.id,
                      program: program, resource_component: resource_component)
  end
  let(:component_1_non_student_resource_2) do
    create(:resource, start_unit_id: program.units.first.id, lesson_id: lesson.id,
                      program: program, resource_component: resource_component)
  end

  let(:resource_component_2) { create(:resource_component, program: program) }
  let(:component_2_student_resource)       do
    create(:resource, start_unit_id: program.units.last.id, lesson_id: lesson.id,
                      program: program, resource_component: resource_component_2,
                      vhl_student_resource: true)
  end
  let(:component_2_student_resource_2)     do
    create(:resource, start_unit_id: program.units.last.id, lesson_id: lesson.id,
                      program: program, resource_component: resource_component_2,
                      vhl_student_resource: true)
  end
  let(:instructor) { build_stubbed(:instructor) }

  def resource_should_be_valid(resource)
    expect(resource).to be_valid
    expect(resource.start_unit_id).to eq(unit_1.id)
    expect(resource.end_unit_id).to eq(unit_2.id)
  end

  before do
    allow(program).to receive(:unit_label).and_return('unit')
    @valid_unit_label = program.unit_label
    @end_unit_field_name = "last_#{@valid_unit_label}".to_sym
  end

  let(:receiver) { component_1_non_student_resource }

  it_should_behave_like 'an object that sanitizes uploaded file names'
  it_should_behave_like 'an object that can read its related file data from an S3 bucket'

  describe 'default_scope' do
    it 'excludes archived resources' do
      archived_resource = create(:resource)
      archived_resource.update!(is_archived: true)
      expect { described_class.find(archived_resource.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'when no title is set' do
    it 'should raise an error' do
      component_1_non_student_resource.title = ''
      expect(component_1_non_student_resource).not_to be_valid
      expect(component_1_non_student_resource.errors.messages[:title]).to include 'is required.'
    end
  end

  context 'when no file name is set' do
    it 'should raise an error' do
      component_1_non_student_resource.file_name = ''
      expect(component_1_non_student_resource).not_to be_valid
      expect(component_1_non_student_resource.errors.messages[:file_name]).to include 'is required.'
    end
  end

  context 'when an invalid unit range is set' do
    it 'should raise an error' do
      resource = build(:resource, title: 'Test resource', program: program, first_unit: program.units.last.id, last_unit: program.units.first.id,  resource_component: resource_component, file_name: 'test_file_name.ext')
      expect { resource.save! }.to raise_error "Validation failed: Last #{@valid_unit_label} must be after First #{@valid_unit_label}."
    end
  end

  context 'program-specific unit labels' do
    let(:unit_1) { build_stubbed(:unit, rank: 1) }
    let(:unit_2) { build_stubbed(:unit, rank: 2) }

    it 'is valid when specifying a unit range using a unit label of lesson' do
      resource = build_stubbed(:resource, title: 'Test resource', first_lesson: unit_1.id, last_lesson: unit_2.id, file_name: 'test_file_name.ext')
      resource_should_be_valid(resource)
    end

    it 'is valid when specifying a unit range using a unit_label of chapter' do
      resource = build_stubbed(:resource, title: 'Test resource', first_chapter: unit_1.id, last_chapter: unit_2.id, program: program, file_name: 'test_file_name.ext')
      resource_should_be_valid(resource)
    end

    it 'is valid when specifying a unit range using a unit_label of theme' do
      resource = build_stubbed(:resource, title: 'Test resource', first_theme: unit_1.id, last_theme: unit_2.id, program: program, file_name: 'test_file_name.ext')
      resource_should_be_valid(resource)
    end

    it 'is valid when specifying a unit range using a unit_label of section' do
      resource = build_stubbed(:resource, title: 'Test resource', first_section: unit_1.id, last_section: unit_2.id, program: program, file_name: 'test_file_name.ext')
      resource_should_be_valid(resource)
    end

    it 'allows mass-assigning a unit label of lesson' do
      expect { described_class.new(title: 'Test resource', first_lesson: unit_1.id, last_lesson: unit_2.id, file_name: 'test_file_name.ext') }.not_to raise_error
    end

    it 'allows mass-assigning a unit label of chapter' do
      expect { described_class.new(title: 'Test resource', first_chapter: unit_1.id, last_chapter: unit_2.id, file_name: 'test_file_name.ext') }.not_to raise_error
    end

    it 'allows mass-assigning a unit label of theme' do
      expect { described_class.new(title: 'Test resource', first_theme: unit_1.id, last_theme: unit_2.id, file_name: 'test_file_name.ext') }.not_to raise_error
    end

    it 'allows mass-assigning a unit label of section' do
      expect { described_class.new(title: 'Test resource', first_section: unit_1.id, last_section: unit_2.id, file_name: 'test_file_name.ext') }.not_to raise_error
    end
  end

  describe 'scopes' do
    describe '.by_file_type' do
      it 'returns only the resources of the given file type' do
        pdf_resource = create(:resource, file_type: 'PDF')
        doc_resource = create(:resource, file_type: 'DOC')
        resources = described_class.by_file_type('PDF')
        expect(resources).to include pdf_resource
        expect(resources).not_to include doc_resource
      end
    end

    describe '.by_source' do
      it 'returns only the resources of the given source' do
        instructor_resource = create(:resource, source: 'instructor')
        vhl_resource = create(:resource, source: 'vhl')
        resources = described_class.by_source('vhl')
        expect(resources).to include vhl_resource
        expect(resources).not_to include instructor_resource
      end
    end

    describe '.by_program' do
      it 'returns only the resources of the given program' do
        another_program = create(:program)
        expected_resource = create(:resource, program: program)
        another_resource = create(:resource, program: another_program)
        resources = described_class.by_program(program)
        expect(resources).to include expected_resource
        expect(resources).not_to include another_resource
      end

      it 'returns only non-archived resources' do
        active_resource = create(:resource, program: program, is_archived: false)
        archived_resource = create(:resource, program: program, is_archived: true)
        resources = described_class.by_program(program)
        expect(resources).to include active_resource
        expect(resources).not_to include archived_resource
      end
    end

    describe '.by_unit' do
      it 'return the resources of a given unit' do
        unit_1 = create(:unit)
        unit_2 = create(:unit)
        resource_unit_1 = create(:resource, start_unit_id: unit_1.id)
        resource_unit_2 = create(:resource, start_unit_id: unit_2.id)
        resources = described_class.by_unit(unit_1)
        expect(resources).to include resource_unit_1
        expect(resources).not_to include resource_unit_2
      end

      it "returns a resources if it's range include the unit" do
        unit = create(:unit, rank: 1, program: program)
        unit_before = create(:unit, rank: 0, program: program)
        unit_after = create(:unit, rank: 2, program: program)
        resource_unit = create(:resource, start_unit_id: unit_before.id, end_unit_id: unit_after.id)
        expect(described_class.by_unit(unit)).to include resource_unit
      end
    end

    describe '.multi_unit' do
      it 'returns only the resources that have a unit range' do
        unit = create(:unit)
        unit_range_resource = create(:resource, start_unit_id: unit.id - 1, end_unit_id: unit.id + 1)
        single_unit_resource = create(:resource, start_unit_id: unit.id)
        resources = described_class.multi_unit
        expect(resources).to include unit_range_resource
        expect(resources).not_to include single_unit_resource
      end
    end

    describe '.by_lesson' do
      it 'returns resources that belong to the specified lesson' do
        lesson_1 = create(:lesson)
        lesson_2 = create(:lesson)
        resource_1 = create(:resource, lesson: lesson_1)
        resource_2 = create(:resource, lesson: lesson_2)

        expect(described_class.by_lesson(lesson_1)).to eq([resource_1])
      end
    end

    describe '.visible_to_students' do
      it 'only returns resources where vhl_student_resource is true' do
        resource       = create(:resource, vhl_student_resource: true)
        other_resource = create(:resource, vhl_student_resource: false)
        expect(described_class.visible_to_students).to eq([resource])
      end
    end

    describe '.group_by_file_type' do
      it 'returns resources grouped by file_type' do
        pdf_resource_1 = create(:resource, file_type: 'pdf')
        pdf_resource_2 = create(:resource, file_type: 'pdf')
        xls_resource_1 = create(:resource, file_type: 'xls')
        resources = described_class.group_by_file_type
        expect(resources.detect { |r| r.file_type == 'pdf' }.resource_file_type_count).to eq(2)
        expect(resources.detect { |r| r.file_type == 'xls' }.resource_file_type_count).to eq(1)
      end
    end

    describe '.group_by_source' do
      it 'returns resources grouped by source' do
        vhl_resource_1 = create(:resource, source: 'VHL')
        vhl_resource_2 = create(:resource, source: 'VHL')
        foo_resource_1 = create(:resource, source: 'FOO')
        resources = described_class.group_by_source
        expect(resources.detect { |r| r.source == 'VHL' }.resource_source_count).to eq(2)
        expect(resources.detect { |r| r.source == 'FOO' }.resource_source_count).to eq(1)
      end
    end

    describe '.group_by_component' do
      let(:resource_component_1) { create(:resource_component) }
      let(:resource_component_2) { create(:resource_component) }
      it 'returns resources grouped by component' do
        audio_script_resource_1 = create(:resource, resource_component: resource_component_1)
        audio_script_resource_2 = create(:resource, resource_component: resource_component_1)
        grammar_resource_2      = create(:resource, resource_component: resource_component_2)
        resources = described_class.group_by_component
        expect(resources.detect { |r| r.resource_component.id == resource_component_1.id }.resource_component_count).to eq(2)
        expect(resources.detect { |r| r.resource_component.id == resource_component_2.id }.resource_component_count).to eq(1)
      end
    end

    describe '.group_by_unit' do
      it 'returns resources grouped by unit' do
        resource_1 = create(:resource, start_unit_id: 1)
        resource_2 = create(:resource, start_unit_id: 1)
        resource_3 = create(:resource, start_unit_id: 2)
        resources = described_class.group_by_unit
        expect(resources.detect { |r| r.start_unit_id == 1 }.resource_unit_count).to eq(2)
        expect(resources.detect { |r| r.start_unit_id == 2 }.resource_unit_count).to eq(1)
      end
    end

    describe '.group_by_lesson' do
      it 'returns resources grouped by lesson' do
        lesson_1 = create(:lesson)
        lesson_2 = create(:lesson)
        resource_1 = create(:resource, lesson: lesson_1)
        resource_2 = create(:resource, lesson: lesson_1)
        resource_3 = create(:resource, lesson: lesson_2)
        resources = described_class.group_by_lesson
        expect(resources.detect { |r| r.lesson_id == lesson_1.id }.resource_lesson_count).to eq(2)
        expect(resources.detect { |r| r.lesson_id == lesson_2.id }.resource_lesson_count).to eq(1)
      end

      it 'does not include resources when the lesson is nil' do
        resource_no_lesson = create(:resource, lesson: nil)
        resources = described_class.group_by_lesson
        expect(resources).to be_empty
      end
    end

    describe '.sorted_by_lesson' do
      it 'returns resources sorted by lesson id' do
        resource_1 = create(:resource, lesson_id: 15, program_id: program.id)
        resource_2 = create(:resource, lesson_id: 10, program_id: program.id)
        resource_3 = create(:resource, lesson_id: nil, program_id: program.id)

        expected_array = [resource_2, resource_1, resource_3]
        expect(described_class.sorted_by_lesson).to eq(expected_array)
      end
    end

    describe '.sorted_by_unit_rank' do
      context 'given two start and end units with ranks' do
        it 'returns the resources ordered by start rank when end ranks are equal' do
          start_unit_1 = create(:unit, rank: 1)
          start_unit_2 = create(:unit, rank: 2)
          start_unit_3 = create(:unit, rank: 3)
          end_unit_1 = create(:unit, rank: 5)
          end_unit_2 = create(:unit, rank: 5)
          end_unit_3 = create(:unit, rank: 5)
          resource_1 = create(:resource, start_unit_id: start_unit_1.id, end_unit_id: end_unit_1.id)
          resource_2 = create(:resource, start_unit_id: start_unit_3.id, end_unit_id: end_unit_3.id)
          resource_3 = create(:resource, start_unit_id: start_unit_2.id, end_unit_id: end_unit_2.id)

          expect(described_class.sorted_by_unit_rank).to eq([resource_1, resource_3, resource_2])
        end

        it 'returns the resources ordered by end rank when start_ranks are equal' do
          start_unit_1 = create(:unit, rank: 1)
          start_unit_2 = create(:unit, rank: 1)
          start_unit_3 = create(:unit, rank: 1)
          end_unit_1 = create(:unit, rank: 1)
          end_unit_2 = create(:unit, rank: 2)
          end_unit_3 = create(:unit, rank: 3)
          resource_1 = create(:resource, start_unit_id: start_unit_1.id, end_unit_id: end_unit_1.id)
          resource_2 = create(:resource, start_unit_id: start_unit_3.id, end_unit_id: end_unit_3.id)
          resource_3 = create(:resource, start_unit_id: start_unit_2.id, end_unit_id: end_unit_2.id)
        end

        it 'returns the resources ordered by start rank and end rank' do
          start_unit_1 = create(:unit, rank: 11)
          start_unit_2 = create(:unit, rank: 11)
          start_unit_3 = create(:unit, rank: 13)
          end_unit_1 = create(:unit, rank: 12)
          end_unit_2 = create(:unit, rank: 11)
          end_unit_3 = create(:unit, rank: 13)
          resource_1 = create(:resource, start_unit_id: start_unit_1.id, end_unit_id: end_unit_1.id)
          resource_2 = create(:resource, start_unit_id: start_unit_3.id, end_unit_id: end_unit_3.id)
          resource_3 = create(:resource, start_unit_id: start_unit_2.id, end_unit_id: end_unit_2.id)

          expect(described_class.sorted_by_unit_rank).to eq([resource_3, resource_1, resource_2])
        end

        it 'sorts start ranks based on integer order, not alphanumberic' do
          start_unit_1 = create(:unit, rank: 1)
          start_unit_2 = create(:unit, rank: 10)
          start_unit_3 = create(:unit, rank: 2)

          resource_1 = create(:resource, start_unit_id: start_unit_1.id)
          resource_2 = create(:resource, start_unit_id: start_unit_2.id)
          resource_3 = create(:resource, start_unit_id: start_unit_3.id)
          expect(described_class.sorted_by_unit_rank).to eq([resource_1, resource_3, resource_2])
        end

        it 'sorts end ranks based on integer order, not alphanumberic' do
          end_unit_1 = create(:unit, rank: 1)
          end_unit_2 = create(:unit, rank: 10)
          end_unit_3 = create(:unit, rank: 2)

          resource_1 = create(:resource, end_unit_id: end_unit_1.id)
          resource_2 = create(:resource, end_unit_id: end_unit_2.id)
          resource_3 = create(:resource, end_unit_id: end_unit_3.id)
          expect(described_class.sorted_by_unit_rank).to eq([resource_1, resource_3, resource_2])
        end

        context 'when a start rank is null' do
          it 'returns a resource with a null start unit last' do
            start_unit_1 = nil
            start_unit_2 = create(:unit, rank: 2)
            start_unit_3 = create(:unit, rank: 1)
            resource_1 = create(:resource, start_unit_id: start_unit_1)
            resource_2 = create(:resource, start_unit_id: start_unit_2.id)
            resource_3 = create(:resource, start_unit_id: start_unit_3.id)

            expect(described_class.sorted_by_unit_rank).to eq([resource_3, resource_2, resource_1])
          end
        end

        context 'when an end rank is null' do
          it 'returns a resource with a null end unit first' do
            end_unit_1 = create(:unit, rank: 2)
            end_unit_2 = nil
            end_unit_3 = create(:unit, rank: 1)
            resource_1 = create(:resource, end_unit_id: end_unit_1.id)
            resource_2 = create(:resource, end_unit_id: end_unit_2)
            resource_3 = create(:resource, end_unit_id: end_unit_3.id)

            expect(described_class.sorted_by_unit_rank).to eq([resource_2, resource_3, resource_1])
          end

          context 'when start and end ranks are equivalent' do
            it 'returns resources based on component name and resource title' do
              start_unit = create(:unit)
              end_unit = create(:unit)
              resource_component_1 = create(:resource_component, name: 'b')
              resource_component_2 = create(:resource_component, name: 'a')
              resource_component_3 = create(:resource_component, name: 'a')
              resource_1 = create(:resource, start_unit_id: start_unit.id, end_unit_id: end_unit.id, resource_component: resource_component_1, title: 'b')
              resource_2 = create(:resource, start_unit_id: start_unit.id, end_unit_id: end_unit.id, resource_component: resource_component_2, title: 'a')
              resource_3 = create(:resource, start_unit_id: start_unit.id, end_unit_id: end_unit.id, resource_component: resource_component_3, title: 'b')
              expect(described_class.sorted_by_unit_rank).to eq([resource_2, resource_3, resource_1])
            end
          end
        end
      end
    end
  end

  describe 'scope-chaining methods' do
    describe '.find_student_resource_for_section' do
      let(:resource) { create(:resource, vhl_student_resource: false) }
      let(:section) { create(:section_with_course) }
      let(:instructor) { section.instructor }

      it 'returns a resource with the specified id made visible by the instructor of the specified section' do
        create(:shown_instructor_resource_setting, resource: resource, instructor: instructor)
        result = described_class.find_student_resource_for_section(resource.id, section)
        expect(result).to eq(resource)
      end
    end

    describe '.find_student_resource' do
      let(:resource) { create(:resource, vhl_student_resource: true) }

      it 'returns a resource with the specified id that is a student resource' do
        result = described_class.find_student_resource(resource.id)
        expect(result).to eq(resource)
      end
    end
  end

  describe '#assessment?' do
    it 'returns false' do
      expect(build_stubbed(:resource).assessment?).to be_falsey
    end
  end

  describe '#location_name' do
    it 'should show the name of the unit for the resource ubication' do
      expect(component_1_non_student_resource.location_name).to eq(program.units.first.display_name)
    end
  end

  # This method should probably be at the class level or as a class method
  # in the Unit class.
  describe '#location_name_for_unit' do
    let(:unit) { create(:unit) }
    let(:resource) { build_stubbed(:resource) }

    it 'returns empty string if the unit does not exist' do
      expect(resource.location_name_for_unit(0)).to eq ''
    end

    it 'returns the unit resources_form_display_name if the unit exists' do
      expected_location_name = 'Resource Display Name'
      unit.update(resources_form_title: expected_location_name)
      expect(resource.location_name_for_unit(unit.id)).to eq expected_location_name
    end
  end

  describe '#unit_options_setting' do
    it "returns 'no_unit' if start unit is not set" do
      resource = create(:resource, vhl_student_resource: false)
      expect(resource.unit_options_setting).to eq('no_unit')
    end

    it "returns 'no_unit' if start unit is set to 'No unit' unit" do
      unit = create(:unit, use_type: 'ResourceUnit')
      resource = create(:resource, start_unit_id: unit.id, vhl_student_resource: false)
      expect(resource.unit_options_setting).to eq('no_unit')
    end

    it "returns 'single_unit' if start unit is set to a different unit from 'No unit' unit and no end unit has been set" do
      resource = build_stubbed(:resource, program: program, start_unit_id: program.units.first.id, vhl_student_resource: false)
      expect(resource.unit_options_setting).to eq('single_unit')
    end

    it "returns 'unit_range' if start and end units are set to a different unit from 'No unit' unit" do
      resource = build_stubbed(:resource, program: program, start_unit_id: program.units.first.id, end_unit_id: program.units.last.id, vhl_student_resource: false)
      expect(resource.unit_options_setting).to eq('unit_range')
    end
  end

  describe '#location_name_start_end_unit' do
    it 'should show the name of the unit for the resource ubication, the start and end unit' do
      resource = build_stubbed(:resource, start_unit_id: program.units.first.id, end_unit_id: program.units.last.id,  lesson_id: lesson.id, program: program, resource_component: resource_component)
      expect(resource.location_name_start_end_unit(program.units.last.id)).to eq("#{program.units.first.display_name} - #{program.units.last.display_name}")
    end
  end

  describe '#component_name' do
    it 'returns empty string if the resource has no component' do
      resource = build_stubbed(:resource, resource_component: nil)
      expect(resource.component_name).to eq('')
    end

    it 'returns empty string if the resource has no component' do
      expect(component_1_non_student_resource.component_name).to eq(resource_component.name)
    end
  end

  describe '#resource_component_names' do
    let(:resource) { create(:resource) }
    let(:resource_component) { instance_double('ResourceComponent', id: 1, name: 'Component name') }

    context 'when resource has a component' do
      before do
        allow(resource).to receive(:resource_component_id).and_return(resource_component.id)
        allow(ResourceComponent).to receive(:find).and_return(resource_component)
      end

      it "returns the component's name" do
        expect(resource.resource_component_names).to eq(resource_component.name)
      end

      context 'when resource has a subcomponent name' do
        it "returns the component and subcomponent's name" do
          allow(resource).to receive(:subcomponent_name).and_return('Subcomponent name')
          expect(resource.resource_component_names).to eq("#{resource_component.name} / #{resource.subcomponent_name}")
        end
      end
    end
  end

  describe '#thumbnail_public_path' do
    it 'returns the image path' do
      expect(component_1_non_student_resource.thumbnail_public_path).not_to be_nil
    end

    context 'with valid file type' do
      context 'audio file' do
        it 'returns an existing file path' do
          component_1_non_student_resource.file_type = 'audio'
          File.exist?("#{Rails.root}/#{component_1_non_student_resource.thumbnail_public_path}")
        end
      end

      context 'document file' do
        it 'returns an existing file path' do
          component_1_non_student_resource.file_type = 'document'
          File.exist?("#{Rails.root}/#{component_1_non_student_resource.thumbnail_public_path}")
        end
      end

      context 'image file' do
        it 'returns an existing file path' do
          component_1_non_student_resource.file_type = 'image'
          File.exist?("#{Rails.root}/#{component_1_non_student_resource.thumbnail_public_path}")
        end
      end

      context 'other file' do
        it 'returns an existing file path' do
          component_1_non_student_resource.file_type = 'other'
          File.exist?("#{Rails.root}/#{component_1_non_student_resource.thumbnail_public_path}")
        end
      end

      context 'pdf file' do
        it 'returns an existing file path' do
          component_1_non_student_resource.file_type = 'PDF'
          File.exist?("#{Rails.root}/#{component_1_non_student_resource.thumbnail_public_path}")
        end
      end

      context 'presentation file' do
        it 'returns an existing file path' do
          component_1_non_student_resource.file_type = 'presentation'
          File.exist?("#{Rails.root}/#{component_1_non_student_resource.thumbnail_public_path}")
        end
      end
    end
  end

  describe '#is_student_viewable?' do
    context 'when instructor' do
      it 'returns true when a resource setting exists for current user and resource' do
        instructor_resource_setting = create(:instructor_resource_setting, resource_id: component_1_non_student_resource.id, instructor: instructor, student_visibility: 'shown')
        is_student_viewable = component_1_non_student_resource.is_student_viewable?(instructor)
        expect(is_student_viewable).to be_truthy
      end

      it 'returns false when a there is no resource setting for current user and resource' do
        instructor_resource_setting = create(:instructor_resource_setting, resource_id: component_2_student_resource.id, instructor: instructor, student_visibility: 'shown')
        is_student_viewable = component_1_non_student_resource.is_student_viewable?(instructor)
        expect(is_student_viewable).to be_falsey
      end

      it 'returns resource value when instructor is not resource editor and no instructor resource setting exists' do
        # Ensure instructor is not a resource editor
        allow(instructor).to receive(:is_resource_editor?).and_return(false)

        # Should return the resource vhl_student_resource value when no instructor_resource_setting
        # and instrucor is not resource editor
        is_student_viewable = component_1_non_student_resource.is_student_viewable?(instructor)
        expect(is_student_viewable).to eq(component_1_non_student_resource.vhl_student_resource)
      end
    end

    context 'when resource editor' do
      it 'obtains the value from the vhl_student_resource field' do
        allow(instructor).to receive(:is_resource_editor?).and_return(true)
        component_1_non_student_resource.vhl_student_resource = true
        expect(component_1_non_student_resource.is_student_viewable?(instructor)).to be_truthy
        component_1_non_student_resource.vhl_student_resource = false
        expect(component_1_non_student_resource.is_student_viewable?(instructor)).to be_falsey
      end
    end
  end

  describe '#instructor_resource_setting' do
    it 'returns a intructor resource setting when a resource setting exists for the resource and the user associated' do
      instructor_resource_setting = create(:instructor_resource_setting, resource_id: component_1_non_student_resource.id, instructor: instructor, student_visibility: 'shown')
      expect(component_1_non_student_resource.instructor_resource_setting(instructor)).to eq(instructor_resource_setting)
    end

    it 'returns nil when a resource setting exists for the resource and the user associated' do
      instructor_resource_setting = create(:instructor_resource_setting, resource_id: component_2_student_resource.id, instructor: instructor, student_visibility: 'shown')
      expect(component_1_non_student_resource.instructor_resource_setting(instructor)).to eq(nil)
    end
  end

  describe '#start_unit' do
    it 'returns nil if no start unit has been set' do
      resource = build_stubbed(:resource, lesson_id: lesson.id, program: program, resource_component: resource_component)
      expect(resource.start_unit).to be_nil
    end

    it 'returns the unit which id is start_unit_id value if set' do
      resource = build_stubbed(:resource, start_unit_id: program.units.first.id, lesson_id: lesson.id, program: program, resource_component: resource_component)
      expect(resource.start_unit).to eq(program.units.first)
    end
  end

  describe '#end_unit' do
    it 'returns nil if no end unit has been set' do
      resource = build_stubbed(:resource, lesson_id: lesson.id, program: program, resource_component: resource_component)
      expect(resource.end_unit).to be_nil
    end

    it 'returns the unit which id is end_unit_id value if set' do
      resource = build_stubbed(:resource, end_unit_id: program.units.last.id, lesson_id: lesson.id, program: program, resource_component: resource_component)
      expect(resource.end_unit).to eq(program.units.last)
    end
  end

  describe '.find_all_for_user_and_section' do
    before do
      @params = {}
      @section = nil
      @user = create(:instructor)
      allow(resource_component).to receive(:resources).and_return([component_1_non_student_resource, component_2_student_resource, component_1_non_student_resource_2, component_2_student_resource_2])
    end

    it 'returns resources for the current program' do
      resources = described_class.find_all_for_user_and_section(program, @user, @params, nil).all_sorted_by_unit_rank
      expect(resources).to match_array([component_1_non_student_resource, component_1_non_student_resource_2, component_2_student_resource, component_2_student_resource_2])
    end

    it 'returns resources ordered by unit' do
      resources = described_class.find_all_for_user_and_section(program, @user, @params, nil).all_sorted_by_unit_rank
      expect(resources.index(component_1_non_student_resource)).to be < resources.index(component_2_student_resource)
    end

    it 'ignores resources for other programs' do
      program_2 = create(:program_with_lessons)
      resource = create(:resource, start_unit_id: program.units.first.id, lesson_id: lesson.id, program: program_2, resource_component: resource_component)
      resources = described_class.find_all_for_user_and_section(program_2, @user, @params, nil).all_sorted_by_unit_rank
      expect(resources).to eq([resource])
    end

    it "doesn't return protected resources for a student when a unit param is specified" do
      unprotected_non_student_resource = create(:resource, start_unit_id: program.units.last.id, lesson_id: lesson.id, program: program, resource_component: resource_component_2, vhl_student_resource: false, protected: false)
      unprotected_student_resource = create(:resource, start_unit_id: program.units.last.id, lesson_id: lesson.id, program: program, resource_component: resource_component_2, vhl_student_resource: true, protected: false)
      protected_resource = create(:resource, start_unit_id: program.units.last.id, lesson_id: lesson.id, program: program, resource_component: resource_component_2, vhl_student_resource: false, protected: true)
      @params[:start_unit_id] = program.units.last.id.to_s
      student = create(:student)
      student_resources = described_class.find_all_for_user_and_section(program, student, @params, @section).all_sorted_by_unit_rank
      expect(student_resources).not_to include protected_resource
      expect(student_resources).not_to include unprotected_non_student_resource
      expect(student_resources).to include unprotected_student_resource
    end

    context 'when resources are associated with different units,' do
      it 'should sort the resources based on unit rank' do
        program_2 = create(:program_with_lessons)
        unit_1 = create(:unit, rank: 2)
        unit_2 = create(:unit, rank: 3)
        unit_3 = create(:unit, rank: 1)
        unit_rank_2_resource = create(:resource, start_unit_id: unit_1.id, lesson_id: lesson.id, program: program_2, resource_component: resource_component)
        unit_rank_3_resource = create(:resource, start_unit_id: unit_2.id, lesson_id: lesson.id, program: program_2, resource_component: resource_component)
        unit_rank_1_resource = create(:resource, start_unit_id: unit_3.id, lesson_id: lesson.id, program: program_2, resource_component: resource_component)
        sorted_resources = described_class.find_all_for_user_and_section(program_2, @user, @params, nil).all_sorted_by_unit_rank
        expect(sorted_resources).to eq([unit_rank_1_resource, unit_rank_2_resource, unit_rank_3_resource])
      end
    end

    context 'when some resources are associated with units and others are not,' do
      it 'returns the resources sorted with the ones with no units at the end' do
        program_2 = create(:program_with_lessons)
        unit_1 = create(:unit, rank: 2)
        no_unit_resource = create(:resource, lesson_id: lesson.id, program: program_2, resource_component: resource_component)
        create(:resource, start_unit_id: unit_1.id, lesson_id: lesson.id, program: program_2, resource_component: resource_component)
        sorted_resources = described_class.find_all_for_user_and_section(program_2, @user, @params, nil).all_sorted_by_unit_rank.to_a
        expect(sorted_resources.last).to eq(no_unit_resource)
      end
    end

    context 'when all units have the same unit,' do
      it 'returns resources sorted by component name' do
        program_2 = create(:program_with_lessons)
        unit_1 = create(:unit, rank: 2)
        resource_component_1 = create(:resource_component, program: program_2, name: 'component 1')
        resource_component_2 = create(:resource_component, program: program_2, name: 'component 2')
        resource_component_3 = create(:resource_component, program: program_2, name: 'component 3')

        component_1_resource = create(:resource, start_unit_id: unit_1.id, lesson_id: lesson.id, program: program_2, resource_component: resource_component_1)
        component_2_resource = create(:resource, start_unit_id: unit_1.id, lesson_id: lesson.id, program: program_2, resource_component: resource_component_2)
        component_3_resource = create(:resource, start_unit_id: unit_1.id, lesson_id: lesson.id, program: program_2, resource_component: resource_component_3)
        sorted_resources = described_class.find_all_for_user_and_section(program_2, @user, @params, nil).all_sorted_by_unit_rank
        expect(sorted_resources).to eq([component_1_resource, component_2_resource, component_3_resource])
      end

      context 'when all resources have the same component,' do
        it 'returns the resource sorted by resource name' do
          program_2 = create(:program_with_lessons)
          unit_1 = create(:unit, rank: 2)
          resource_component_1 = create(:resource_component, program: program_2, name: 'component 1')
          named_resource_1 = create(:resource, title: 'resource 3', start_unit_id: unit_1.id, lesson_id: lesson.id, program: program_2, resource_component: resource_component_1)
          named_resource_2 = create(:resource, title: 'resource 1', start_unit_id: unit_1.id, lesson_id: lesson.id, program: program_2, resource_component: resource_component_1)
          named_resource_3 = create(:resource, title: 'resource 2', start_unit_id: unit_1.id, lesson_id: lesson.id, program: program_2, resource_component: resource_component_1)
          sorted_resources = described_class.find_all_for_user_and_section(program_2, @user, @params, nil).all_sorted_by_unit_rank
          expect(sorted_resources).to include(named_resource_2, named_resource_3, named_resource_1)
          expect(sorted_resources.count).to eq(3)
        end
      end
    end

    context 'when user is a student,' do
      before do
        @user = create(:student)
        @instructor = create(:instructor)
        @section = create(:section, instructor: @instructor)
      end

      it 'returns student resources' do
        student_resources = described_class.find_all_for_user_and_section(program, @user, @params, @section).all_sorted_by_unit_rank
        expect(student_resources).to match_array([component_2_student_resource, component_2_student_resource_2])
      end

      it 'ignores non-student resources' do
        student_resources = described_class.find_all_for_user_and_section(program, @user, @params, @section).all_sorted_by_unit_rank
        expect(student_resources).not_to include component_1_non_student_resource
        expect(student_resources).not_to include component_1_non_student_resource_2
      end

      it 'ignores protected resources' do
        protected_resource_1 = create(:resource, unit: program.units.last, lesson_id: lesson.id, program: program, resource_component: resource_component_2, vhl_student_resource: true, protected: true)
        protected_resource_2 = create(:resource, unit: program.units.last, lesson_id: lesson.id, program: program, resource_component: resource_component_2, vhl_student_resource: true, protected: true)
        student_resources = described_class.find_all_for_user_and_section(program, @user, @params, @section).all_sorted_by_unit_rank
        expect(student_resources).not_to include protected_resource_1
        expect(student_resources).not_to include protected_resource_2
      end

      it "returns resources that current student's instructor has uploaded and made visible to students" do
        visible_uploaded_resource = create(:resource, unit: program.units.last, lesson_id: lesson.id,
                                                      program: program, resource_component: resource_component_2,
                                                      uploaded: true, owner_id: @instructor.id)
        create(:instructor_resource_setting, instructor: @instructor, resource_id: visible_uploaded_resource.id,
                                             student_visibility: 'shown')
        expect(described_class.find_all_for_user_and_section(program, @user, @params, @section).all_sorted_by_unit_rank).to include visible_uploaded_resource
      end

      it "does not return resources that current student's instructor has uploaded but not made visible to students" do
        non_visibile_uploaded_resource = create(:resource, unit: program.units.last, lesson_id: lesson.id,
                                                           program: program, resource_component: resource_component_2,
                                                           uploaded: true, owner_id: @instructor.id)
        expect(described_class.find_all_for_user_and_section(program, @user, @params, @section).all_sorted_by_unit_rank).not_to include non_visibile_uploaded_resource
      end

      it 'does not return resources that a different instructor has uploaded and made visible to students' do
        other_instructor = create(:instructor)
        other_instructor_uploaded_resource = create(:resource, unit: program.units.last, lesson_id: lesson.id,
                                                               program: program, resource_component: resource_component_2,
                                                               uploaded: true, owner_id: other_instructor.id)
        create(:instructor_resource_setting, instructor: other_instructor, resource_id: other_instructor_uploaded_resource.id,
                                             student_visibility: 'shown')
        expect(described_class.find_all_for_user_and_section(program, @user, @params, @section).all_sorted_by_unit_rank).not_to include other_instructor_uploaded_resource
      end

      context 'when the instructor for the section has marked non-student resources as student-viewable,' do
        it 'returns the resources marked as student-viewable' do
          params = {}
          non_student_resource = create(:resource, unit: program.units.first, lesson_id: lesson.id, program: program,
                                                   resource_component: resource_component, vhl_student_resource: false)
          create(:instructor_resource_setting, instructor: @instructor, resource_id: non_student_resource.id,
                                               student_visibility: 'shown')
          resources = described_class.find_all_for_user_and_section(program, @user, params, @section).all_sorted_by_unit_rank
          expect(resources).to include non_student_resource
        end
      end

      context 'when the instructor for the section has marked student resources as student-viewable-hidden,' do
        it 'ignores the resources marked as student-viewable-hidden' do
          params = {}
          non_student_resource = create(:resource, unit: program.units.first, lesson_id: lesson.id, program: program, resource_component: resource_component, vhl_student_resource: true)
          instructor_resource_setting = create(:instructor_resource_setting, instructor: @instructor, resource_id: non_student_resource.id, student_visibility: 'hidden')
          resources = described_class.find_all_for_user_and_section(program, @user, params, @section).all_sorted_by_unit_rank
          expect(resources).not_to include non_student_resource
        end
      end

      context 'when the instructor assigns a due date for resource' do
        it 'should return the resource even if is not visible to student' do
          params = {}
          assigned_student_resource = create(:resource, unit: program.units.first, lesson_id: lesson.id, program: program,
                                                        resource_component: resource_component, vhl_student_resource: false)
          instructor_resource_setting = create(:instructor_resource_setting, instructor: @instructor, resource_id: assigned_student_resource.id, student_visibility: 'hidden')
          create(:assignment, assignable_type: 'Resource', assignable_id: assigned_student_resource.id, section: @section)
          resources = described_class.find_all_for_user_and_section(program, @user, params, @section).all_sorted_by_unit_rank
          expect(resources).to include assigned_student_resource
        end
      end
    end

    context 'when user is an instructor,' do
      it 'returns student resources' do
        results = described_class.find_all_for_user_and_section(program, @user, @params, nil).all_sorted_by_unit_rank
        expect(results).to include component_2_student_resource
        expect(results).to include component_2_student_resource_2
      end

      it 'returns non-student resources' do
        results = described_class.find_all_for_user_and_section(program, @user, @params, nil).all_sorted_by_unit_rank
        expect(results).to include component_1_non_student_resource
        expect(results).to include component_1_non_student_resource_2
      end

      it 'returns resources that current user has uploaded' do
        my_uploaded_resource = create(:resource, unit: program.units.last, lesson_id: lesson.id,
                                                 program: program, resource_component: resource_component_2,
                                                 uploaded: true, owner_id: @user.id)
        expect(described_class.find_all_for_user_and_section(program, @user, @params, nil).all_sorted_by_unit_rank).to include my_uploaded_resource
      end

      it 'does not return resources that a different instructor has uploaded' do
        other_instructor_uploaded_resource = create(:resource, unit: program.units.last, lesson_id: lesson.id,
                                                               program: program, resource_component: resource_component_2,
                                                               uploaded: true, owner_id: create(:instructor).id)
        expect(described_class.find_all_for_user_and_section(program, @user, @params, nil).all_sorted_by_unit_rank).not_to include other_instructor_uploaded_resource
      end
    end

    context 'when a unit_id param is passed,' do
      context 'when there are resources with just a start unit' do
        it 'returns resources with the start unit rank equal to the specified unit rank' do
          program = create(:program_with_lessons)
          same_unit_resource_1 = create(:resource, title: 'Resource 1', start_unit_id: program.units.last.id, program: program)
          same_unit_resource_2 = create(:resource, title: 'Resource 2', start_unit_id: program.units.last.id, program: program)
          another_unit_resource = create(:resource, title: 'Resource 2', start_unit_id: program.units.first.id, program: program)
          params = { start_unit_id: program.units.last.id.to_s }
          unit_resources = described_class.find_all_for_user_and_section(program, @user, params, nil).all_sorted_by_unit_rank
          expect(unit_resources.include?(same_unit_resource_1)).to be_truthy
          expect(unit_resources.include?(same_unit_resource_2)).to be_truthy
          expect(unit_resources.size).to eq(2)
        end

         it 'ignores resources with no start unit' do
           program = create(:program_with_lessons)
          create(:resource, title: 'Resource 1', program: program)
          unit_resource = create(:resource, title: 'Resource 2', start_unit_id: program.units.last.id, program: program)
          params = { start_unit_id: program.units.last.id.to_s }
          unit_resources = described_class.find_all_for_user_and_section(program, @user, params, nil).all_sorted_by_unit_rank
          expect(unit_resources).to eq([unit_resource])
         end

         it 'ignores resources with a start unit that is different from the specified unit' do
           program = create(:program_with_lessons)
          expected_resource = create(:resource, title: 'Resource 1', start_unit_id: program.units.first.id, program: program)
          create(:resource, title: 'Resource 2', start_unit_id: program.units.last.id, program: program)
          params = { start_unit_id: program.units.first.id.to_s }
          unit_resources = described_class.find_all_for_user_and_section(program, @user, params, nil).all_sorted_by_unit_rank
          expect(unit_resources).to eq([expected_resource])
         end
      end

      context 'when there are resources with a start unit and end unit' do
        it 'returns the resources between a Unit rank range' do
          program = create(:program_with_lessons)
         unit_resource_1 = create(:resource, start_unit_id: program.units.first.id, end_unit_id: program.units.last.id, program: program)
         unit_resource_2 = create(:resource, start_unit_id: program.units.last.id, program: program)
         params = { start_unit_id: program.units.last.id.to_s }
         unit_resources = described_class.find_all_for_user_and_section(program, @user, params, nil).all_sorted_by_unit_rank
         expect(unit_resources).to eq([unit_resource_1, unit_resource_2])
        end

        it 'returns resources where the start unit rank is equal to the specified unit rank' do
          program = create(:program_with_lessons)
          unit_resource_1 = create(:resource, start_unit_id: program.units.first.id, end_unit_id: program.units.last.id, program: program)
          unit_resource_2 = create(:resource, start_unit_id: program.units.first.id, end_unit_id: program.units.last.id, program: program)
          params = { start_unit_id: program.units.first.id.to_s }
          unit_resources = described_class.find_all_for_user_and_section(program, @user, params, nil).all_sorted_by_unit_rank
          expect(unit_resources.include?(unit_resource_1)).to be_truthy
          expect(unit_resources.include?(unit_resource_2)).to be_truthy
          expect(unit_resources.size).to eq(2)
        end

        it 'returns resources where the end unit is equal to the specified unit' do
          program = create(:program_with_lessons)
          unit_resource_1 = create(:resource, start_unit_id: program.units.first.id, end_unit_id: program.units.last.id, program: program)
          unit_resource_2 = create(:resource, start_unit_id: program.units.first.id, end_unit_id: program.units.last.id, program: program)
          params = { start_unit_id: program.units.last.id.to_s }
          unit_resources = described_class.find_all_for_user_and_section(program, @user, params, nil).all_sorted_by_unit_rank
          expect(unit_resources.include?(unit_resource_1)).to be_truthy
          expect(unit_resources.include?(unit_resource_2)).to be_truthy
          expect(unit_resources.size).to eq(2)
        end

        it 'returns resources where the specified unit is between the start unit and end unit' do
          Unit.destroy_all
          program = create(:program)
          (1..10).each { |n| create(:unit, id: n, rank: n, program: program) }
          unit_resource_1 = create(:resource, title: 'Resource 1', start_unit_id: program.units.first.id, end_unit_id: program.units.last.id, program: program)
          unit_resource_2 = create(:resource, title: 'Resource 2', start_unit_id: program.units.first.id, end_unit_id: program.units[3].id, program: program)
          unit_resource_3 = create(:resource, title: 'Resource 3', start_unit_id: program.units[7].id, end_unit_id: program.units.last.id, program: program)
          unit_resource_4 = create(:resource, title: 'Resource 4', start_unit_id: program.units[3].id, end_unit_id: program.units[6].id, program: program)
          unit_resource_5 = create(:resource, title: 'Resource 5', start_unit_id: program.units[4].id, end_unit_id: program.units[5].id, program: program)
          params = { start_unit_id: program.units[4].id.to_s }
          unit_resources = described_class.find_all_for_user_and_section(program, @user, params, nil).all_sorted_by_unit_rank
          expect(unit_resources).to include unit_resource_1
          expect(unit_resources).to include unit_resource_4
          expect(unit_resources).to include unit_resource_5
          expect(unit_resources).not_to include unit_resource_2
          expect(unit_resources).not_to include unit_resource_3
          expect(unit_resources.size).to eq(3)
        end

        it 'ignores resources where the start unit rank is greater than the speciifed unit rank' do
          program = create(:program_with_lessons)
          create(:resource, start_unit_id: program.units.first.id, end_unit_id: program.units.last.id, program: program)
          create(:resource, start_unit_id: program.units.first.id, end_unit_id: program.units.last.id, program: program)
          params = { start_unit_id: program.units.first.id.to_i - 1 }
          unit_resources = described_class.find_all_for_user_and_section(program, @user, params, nil).all_sorted_by_unit_rank
          expect(unit_resources).to eq([])
        end

        it 'ignores resources where the end unit rank is less than the specified start unit' do
          program = create(:program_with_lessons)
          create(:resource, start_unit_id: program.units.first.id, end_unit_id: program.units.last.id, program: program)
          create(:resource, start_unit_id: program.units.first.id, end_unit_id: program.units.last.id, program: program)
          params = { start_unit_id: create(:unit, program: program, rank: 99).id }
          unit_resources = described_class.find_all_for_user_and_section(program, @user, params, nil).all_sorted_by_unit_rank
          expect(unit_resources).to eq([])
        end
      end

      it 'returns resources from the specified unit' do
        params = { start_unit_id: program.units.first.id.to_s }
        unit_resources = described_class.find_all_for_user_and_section(program, @user, params, nil).all_sorted_by_unit_rank
        expect(unit_resources).to match_array([component_1_non_student_resource, component_1_non_student_resource_2])
      end

      it 'ignores resources from other units' do
        params = { start_unit_id: program.units.first.id.to_s }
        unit_resources = described_class.find_all_for_user_and_section(program, @user, params, nil).all_sorted_by_unit_rank
        expect(unit_resources).not_to include component_2_student_resource
        expect(unit_resources).not_to include component_2_student_resource_2
      end
    end

    context 'when a component_id param is passed,' do
      before do
        @params = { component_id: resource_component_2.id.to_s }
      end

      it 'returns resources with the specified component_id' do
        resources_by_component = described_class.find_all_for_user_and_section(program, @user, @params, nil).all_sorted_by_unit_rank
        expect(resources_by_component).to include component_2_student_resource
        expect(resources_by_component).to include component_2_student_resource_2
      end

      it 'ignores resources from other components' do
        other_resource_component = create(:resource_component, program: program)
        other_resource = create(:resource, unit: program.units.last, lesson_id: lesson.id, program: program, resource_component: other_resource_component, vhl_student_resource: true)
        resources_by_component = described_class.find_all_for_user_and_section(program, @user, @params, nil).all_sorted_by_unit_rank
        expect(resources_by_component).not_to include other_resource
      end
    end
  end

  describe '#file_path' do
    context 'when resource was uploaded by instructor' do
      it 'returns the directory path for uploaded file' do
        instructor = create(:instructor)
        uploaded_resource = create(:resource,
                                   unit: program.units.first,
                                   lesson_id: lesson.id,
                                   program: program,
                                   resource_component: resource_component,
                                   owner_id: instructor.id,
                                   file_name: 'file_name.ext',
                                   uploaded: true)

        expected_file_path = File.join('resources', M3::Application.config.current_deployed_env_name,
                                       program.id.to_s, 'uploaded', instructor.id.to_s, uploaded_resource.id.to_s, uploaded_resource.file_name)
        expect(uploaded_resource.file_path).to eql expected_file_path
      end
    end

    context "when resource wasn't uploaded" do
      it 'returns the directory path for file' do
        instructor = create(:instructor)
        uploaded_resource = create(:resource,
                                   unit: program.units.first,
                                   lesson_id: lesson.id,
                                   program: program,
                                   resource_component: resource_component,
                                   owner_id: instructor.id,
                                   file_name: 'file_name.ext',
                                   uploaded: false)

        expected_file_path = File.join('resources', M3::Application.config.current_deployed_env_name,
                                       program.id.to_s, uploaded_resource.id.to_s, uploaded_resource.file_name)
        expect(uploaded_resource.file_path).to eql expected_file_path
      end
    end
  end

  describe '#owner?' do
    it 'returns true when user uploaded a specific resource' do
      instructor = create(:instructor)
      resource = create(:resource, uploaded: true, owner_id: instructor.id)
      expect(resource.owner?(instructor.id)).to eq(true)
    end

    it 'returns false when resource was uploaded by another instructor' do
      instructor = create(:instructor)
      another_instructor = create(:instructor)
      resource = create(:resource, uploaded: true, owner_id: instructor.id)
      expect(resource.owner?(another_instructor.id)).to eq(false)
    end
  end

  describe '#toc_location' do
    it 'returns nil' do
      resource = create(:resource)
      expect(resource.toc_location).to be_nil
    end
  end

  describe '.visible_by_instructor' do
    let(:instructor_1) { create(:instructor) }
    let(:instructor_2) { create(:instructor) }
    let(:section) { create(:section) }

    context 'when a resource is visible to students' do
      let!(:shown_resource)  { create(:resource, vhl_student_resource: true) }
      let!(:hidden_resource) { create(:resource, vhl_student_resource: true) }

      context 'given an instructor has set the visibility to "shown"' do
        it 'returns the resource' do
          create(:shown_instructor_resource_setting, resource: shown_resource, instructor: instructor_1)
          create(:hidden_instructor_resource_setting, resource: hidden_resource, instructor: instructor_1)
          expect(described_class.visible_by_instructor(instructor_1, section)).to eq([shown_resource])
        end
      end

      context 'given there is no setting for the resource but it is a vhl student resource' do
        it 'returns all student-visible resources' do
          expect(described_class.visible_by_instructor(instructor_1, section)).to match_array([shown_resource, hidden_resource])
        end
      end

      context 'given there is an assigned resource' do
        it 'returns the resource' do
          assignment = create(:assignment, section: section, assignable: shown_resource)
          hidden_resource.update!(vhl_student_resource: false)
          expect(described_class.visible_by_instructor(instructor_1, section)).to match_array([shown_resource])
        end
      end
    end

    context 'when a resource is hidden from students' do
      let!(:shown_resource)  { create(:resource, vhl_student_resource: false) }
      let!(:hidden_resource) { create(:resource, vhl_student_resource: false) }

      context 'given an instructor has made it visible' do
        it 'returns the resource' do
          create(:shown_instructor_resource_setting, resource: shown_resource, instructor: instructor_1)
          create(:hidden_instructor_resource_setting, resource: hidden_resource, instructor: instructor_1)
          expect(described_class.visible_by_instructor(instructor_1, section)).to eq([shown_resource])
        end

        it 'does not return the resource if another instructor has made it visible' do
          create(:shown_instructor_resource_setting, resource: shown_resource, instructor: instructor_2)
          expect(described_class.visible_by_instructor(instructor_1, section)).to be_empty
        end
      end

      context 'given an instructor has assigned the resource' do
        it 'returns the resource' do
          create(:hidden_instructor_resource_setting, resource: shown_resource, instructor: instructor_1)
          assignment = create(:assignment, section: section, assignable: shown_resource)
          expect(described_class.visible_by_instructor(instructor_1, section)).to eq([shown_resource])
        end
      end

      context 'given there is no setting for the resource' do
        it 'does not return the resource' do
          expect(described_class.visible_by_instructor(instructor_1, section)).to be_empty
        end
      end
    end
  end

  describe '#editable_by?' do
    let(:instructor) { build_stubbed(:instructor) }

    context 'with a user-uploaded resource' do
      it 'is true if user is the owner' do
        resource = build_stubbed(:resource, uploaded: true, owner_id: instructor.id)
        expect(resource).to be_editable_by instructor
      end

      it 'is false if user is not the owner' do
        other_instructor = build_stubbed(:instructor)
        resource = build_stubbed(:resource, uploaded: true, owner: other_instructor)
        expect(resource).not_to be_editable_by instructor
      end
    end

    context 'with a resource that is not user-uploaded' do
      let(:resource) { build_stubbed(:resource, uploaded: false) }

      it 'is true if user has the resource editor role' do
        allow(instructor).to receive(:is_resource_editor?).and_return(true)
        expect(resource).to be_editable_by instructor
      end

      it 'is false if user does not have the resource editor role' do
        allow(instructor).to receive(:is_resource_editor?).and_return(false)
        expect(resource).not_to be_editable_by instructor
      end
    end
  end

  describe '#upload_file' do
    let(:s3_bucket) { double(Radner::S3Storage) }
    let(:file) { StringIO.new }

    before do
      allow(Radner::S3Storage).to receive(:new).and_return(s3_bucket)
    end

    context 'when file is an rtf' do
      it 'sets the content_type is S3' do
        rtf_resource = create(:resource)
        file_path = 'resources/some_file.rtf'
        allow(rtf_resource).to receive(:file_path).and_return(file_path)
        expect(s3_bucket).to receive(:store_file_contents!).with(
          file_path,
          file.read,
          { content_disposition: 'attachment', content_type: 'application/rtf' }
        )
        rtf_resource.upload_file(file)
      end
    end
  end
end
