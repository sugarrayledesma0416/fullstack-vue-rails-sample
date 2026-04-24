describe CustomRubricLoader do
  include ActivityXmlContentHelper

  def generate_rubric_xml(criteria_title)
    <<~XML
      <rubric id="123" rubric_revision_id="456">
        <header_row>
          <header_column id="1">col_header</header_column>
        </header_row>
        <criteria>
          <title>#{criteria_title}</title>
          <performance header_id="1">
            <description>description</description>
            <score>5</score>
          </performance>
        </criteria>
      </rubric>
    XML
  end

  def create_custom_rubric(attrs = {})
    CustomRubric.create!(
      {
        activity_id: activity.id,
        course_id: course.id,
        draft: false,
        instructor_id: instructor.id,
        source_activity:,
        source_rubric_id: 1,
        stored_rubric: nil
      }.merge(attrs)
    )
  end

  let(:program) { create(:program_with_toc_entries) }
  let(:unit) { program.units.first }
  let(:strand) do
    test_strand = lesson.strands.first
    test_strand.location = concept.id
    test_strand.save!
    test_strand
  end
  let(:lesson) { unit.lessons.first }
  let!(:concept) { create(:concept, lesson:, program:) }
  let(:instructor) { create(:instructor) }
  let(:course) { create(:course, owner: instructor, program:) }
  let(:section) { create(:section, course:, instructor:) }
  let(:source_activity) { create(:activity, concept:, lesson:) }

  let(:criteria_title) { new_rubric.criterias.first.title }

  let(:activity) do
    create(
      :instructor_created_activity,
      concept:,
      instructor:,
      lesson:,
      toc_entry_id: strand.location,
      randomizable: false
    )
  end

  before do
    allow(Maestro::LicenseGroup).to receive(:all).and_return(
      [instance_double(Maestro::LicenseGroup, id: 1, name: '01-Supersite')]
    )

    # Avoid errors trying to store denormalized attrs for source_activity
    allow(Activity).to receive(:filepath_from_revision_id).with(
      anything, false, false
    ).and_return('')
    allow(Activity).to receive(:filepath_from_revision_id).with(
      anything, true, false
    ).and_return(content_filepath)
  end

  shared_examples 'loading an external rubric' do
    context 'with an activity with an external rubric,' do
      let(:new_rubric) { activity.content_object.external_rubric.rubric }

      let(:content_filepath) do
        File.join('spec', 'fixtures', 'xml', 'composition_with_external_rubric.xml')
      end

      it 'does not update the external_rubric content if no CustomRubric ' \
         'record exists' do
        loader.load_xml_from_custom_rubric

        expect(criteria_title).to eq('old_criteria_title')
      end

      it 'does not update the external_rubric content if no CustomRubric ' \
         'record exists with the correct course_id and source_rubric_id' do
        new_xml = generate_rubric_xml('new_title')

        other_course = create(:course, owner: instructor, program:)
        create_custom_rubric(course_id: other_course.id, stored_rubric: new_xml)
        create_custom_rubric(source_rubric_id: 2, stored_rubric: new_xml)

        loader.load_xml_from_custom_rubric

        expect(criteria_title).to eq('old_criteria_title')
      end

      it 'does not update the external_rubric content if only ' \
         'CustomRubric records with draft set to true exist' do
        new_xml = generate_rubric_xml('new_title')

        create_custom_rubric(
          course_id: course.id,
          draft: true,
          source_rubric_id: 1,
          stored_rubric: new_xml
        )

        loader.load_xml_from_custom_rubric

        expect(criteria_title).to eq('old_criteria_title')
      end

      it 'updates the external_rubric content if a CustomRubric record ' \
         'exists with the correct course_id and source_rubric_id' do
        new_xml = generate_rubric_xml('new_title')

        create_custom_rubric(
          course_id: course.id,
          source_rubric_id: 1,
          stored_rubric: new_xml
        )

        loader.load_xml_from_custom_rubric

        expect(criteria_title).to eq('new_title')
      end
    end
  end

  shared_examples 'loading an inline rubric' do
    context 'with an activity with an inline rubric,' do
      let(:new_rubric) { activity.content_object.inline_rubric.first.rubric }

      let(:content_filepath) do
        File.join('spec', 'fixtures', 'xml', 'hybrid_reading_with_inline_rubric.xml')
      end

      it 'does not update the inline_rubric content if no CustomRubric ' \
         'record exists' do
        loader.load_xml_from_custom_rubric

        expect(criteria_title).to eq('old_criteria_title')
      end

      it 'does not update the inline_rubric content if no CustomRubric ' \
         'record exists with the correct course_id and source_rubric_id' do
        new_xml = generate_rubric_xml('new_title')

        other_course = create(:course, owner: instructor, program:)
        create_custom_rubric(course_id: other_course.id, stored_rubric: new_xml)
        create_custom_rubric(source_rubric_id: 2, stored_rubric: new_xml)

        loader.load_xml_from_custom_rubric

        expect(criteria_title).to eq('old_criteria_title')
      end

      it 'does not update the inline_rubric content if only ' \
         'CustomRubric records with draft set to true exist' do
        new_xml = generate_rubric_xml('new_title')

        create_custom_rubric(
          course_id: course.id,
          draft: true,
          source_rubric_id: 1,
          stored_rubric: new_xml
        )

        loader.load_xml_from_custom_rubric

        expect(criteria_title).to eq('old_criteria_title')
      end

      it 'updates the inline_rubric content if a CustomRubric record ' \
         'exists with the correct course_id and source_rubric_id' do
        new_xml = generate_rubric_xml('new_title')

        create_custom_rubric(
          course_id: course.id,
          source_rubric_id: 1,
          stored_rubric: new_xml
        )

        loader.load_xml_from_custom_rubric

        expect(criteria_title).to eq('new_title')
      end
    end
  end

  shared_examples 'with a vhl-authored activity without inline or external rubrics' do
    let(:content_filepath) do
      File.join('spec', 'fixtures', 'xml', 'composition_with_rubric.xml')
    end
    let(:content_object) do
      xml = File.new('spec/fixtures/xml/composition_with_rubric.xml')
      content_object_from_xml(xml)
    end

    it 'returns nil' do
      activity = create(:activity)
      allow(activity).to receive(:content_object).and_return(content_object)
      original_rubric = activity.rubric
      loader = described_class.new(activity, instructor, section)
      loader.course = section.course

      expect(loader.load_xml_from_custom_rubric).to be_nil
      expect(activity.rubric).to eq original_rubric
    end
  end

  shared_examples 'with a copy of a vhl-authored activity without inline or external rubrics' do
    let(:content_filepath) do
      File.join('spec', 'fixtures', 'xml', 'composition_with_rubric.xml')
    end
    let(:content_object) do
      xml = File.new('spec/fixtures/xml/composition_with_rubric.xml')
      content_object_from_xml(xml)
    end
    let(:instructor_revision_id) do
      100
    end

    it 'returns the last version of the custom rubric for that activity' do
      activity = create(:activity, instructor_revision_id:)
      allow(activity).to receive(:content_object).and_return(content_object)
      loader = described_class.new(activity, instructor, section)
      loader.course = section.course

      # create first revision
      first_revision_xml = generate_rubric_xml('first edited title')
      create_custom_rubric(course_id: section.course_id, stored_rubric: first_revision_xml)
      # create second revision
      second_revision_xml = generate_rubric_xml('second edited title')
      create_custom_rubric(course_id: section.course_id, stored_rubric: second_revision_xml)

      loader.load_xml_from_custom_rubric
      expect(activity.rubric.criterias.first.title).to eq 'second edited title'
    end
  end

  context 'with an instructor,' do
    let(:loader) { described_class.new(activity, instructor, section) }

    include_examples 'loading an external rubric'
    include_examples 'loading an inline rubric'
    include_examples 'with a vhl-authored activity without inline or external rubrics'
    include_examples 'with a copy of a vhl-authored activity without inline or external rubrics'

    shared_context 'custom rubric for focused course' do
      let(:focused_course) { create(:course, owner: instructor, program:) }
      let(:focused_section) { create(:section, course: focused_course, instructor:) }

      let(:focus) do
        Focus.new(
          instructor,
          program,
          { program.id.to_s => { section_id: focused_section.id } }
        )
      end

      let(:loader) { described_class.new(activity, instructor, nil, focus) }

      before do
        new_xml = generate_rubric_xml('new_title')
        create_custom_rubric(
          course_id: focused_course.id,
          stored_rubric: new_xml
        )
      end
    end

    context 'with an activity with an external rubric,' do
      let(:new_rubric) { activity.content_object.external_rubric.rubric }

      let(:content_filepath) do
        File.join('spec', 'fixtures', 'xml', 'composition_with_external_rubric.xml')
      end

      include_context 'custom rubric for focused course'

      it 'loads the custom rubric from the focused course if a focus arg ' \
         'is specified' do
        loader.load_xml_from_custom_rubric

        expect(criteria_title).to eq('new_title')
      end
    end

    context 'with an activity with an inline rubric,' do
      let(:new_rubric) { activity.content_object.inline_rubric.first.rubric }

      let(:content_filepath) do
        File.join('spec', 'fixtures', 'xml', 'hybrid_reading_with_inline_rubric.xml')
      end

      include_context 'custom rubric for focused course'

      it 'loads the custom rubric from the focused course if a focus arg ' \
         'is specified' do
        loader.load_xml_from_custom_rubric

        expect(criteria_title).to eq('new_title')
      end
    end
  end

  context 'with a student,' do
    let(:student) { create(:student) }
    let(:loader) { described_class.new(activity, student, section) }

    include_examples 'loading an external rubric'
    include_examples 'loading an inline rubric'
    include_examples 'with a vhl-authored activity without inline or external rubrics'
    include_examples 'with a copy of a vhl-authored activity without inline or external rubrics'
  end
end
