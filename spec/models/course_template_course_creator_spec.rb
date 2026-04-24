describe CourseTemplateCourseCreator do
  # The CourseTemplateCourseCreator should
  # * create a new course
  # * set its name to the given name
  # * set its source template ID to the given ID
  # * create new copies of any categories in the template course
  #   and assign them to new course
  #
  # QUESTION: how about course library activities?

  let(:program) { create(:program) }
  let(:course_template) { create(:course_template, program: program) }
  let(:template_category_1) { create(:category, course: course_template, name: 'Pride') }
  let(:template_category_2) { create(:category, course: course_template, name: 'Prejudice') }
  let(:section_template_1) { create(:section, course: course_template) }
  let(:section_template_2) { create(:section, course: course_template) }
  let(:source_template_id) { course_template.id }
  let(:course_name) { 'course_of_a_different_color' }
  let(:section_1_name) { 'sección uno' }
  let(:section_2_name) { 'sección dos' }
  let(:section_3_name) { 'sección tres' }
  let(:last_course) { Course.last }
  let(:course_owner) { create(:instructor) }
  let(:coinstructor) { create(:instructor) }
  let(:assistant) { create(:instructor) }

  let(:params) do
    {
      owner_id: course_owner.id,
      name: course_name,
      source_template_id: source_template_id
    }
  end

  describe '#initialize' do
    it 'raises an error if source template does not exist' do
      # Instantiate template, get its ID, and create params.
      course_template
      source_template_id
      params

      # Delete template so that ID still exists and template doesn't.
      Course.templates.delete(source_template_id)

      expect do
        described_class.new(params)
      end.to raise_error("There is no course template with id = #{source_template_id}.")
    end
  end

  describe '#create_course' do
    before do
      # Bring template and categories into existence
      course_template
      template_category_1
      template_category_2

      # Stub course license copy
      allow(Maestro::CourseLicense).to receive(:copy).and_return(true)

      described_class.new(params).create_course
    end

    it 'creates a course with the given name' do
      expect(last_course.name).to eq(course_name)
    end

    it 'creates a course with the given source_template_id' do
      expect(last_course.source_template_id).to eq(source_template_id)
    end

    it 'copies categories for the course template to new categories' do
      new_categories = Category.where(course: last_course)
      expect(new_categories.map(&:name)).to match_array(%w[Pride Prejudice])
    end

    it 'calls course-license copy with the expected params' do
      expect(Maestro::CourseLicense).to have_received(:copy)
        .with(course_template.guid, last_course.guid)
    end

    it 'creates hidden CourseLibraryActivity records only for shared IGC ' \
       'activities in the program and school of the course template' do
      allow(Maestro::LicenseGroup).to receive(:all)
        .and_return([Maestro::LicenseGroup.new('name' => '01-Supersite')])
      unit = create(:unit, program: program)
      strand = create(:toc_entry)
      lesson = create(:lesson, toc_entries: [strand], unit: unit)
      concept = create(
        :concept,
        id: strand.location,
        lesson: lesson,
        program: program
      )

      other_school = create(:school)

      other_program = create(:program)
      other_program_unit = create(:unit, program: other_program)
      other_program_strand = create(:toc_entry)

      other_program_lesson = create(
        :lesson,
        toc_entries: [other_program_strand],
        unit: other_program_unit
      )
      other_program_concept = create(
        :concept,
        id: other_program_strand.location,
        lesson: other_program_lesson,
        program: other_program
      )

      other_program_igc = create(
        :instructor_created_activity,
        concept: other_program_concept,
        lesson: other_program_lesson,
        toc_location: other_program_strand.location
      )
      create(
        :shared_library_activity,
        activity: other_program_igc,
        is_shared: true,
        school: course_template.school,
        source_activity: other_program_igc
      )

      non_approved_igc = create(
        :instructor_created_activity,
        concept: concept,
        lesson: lesson,
        toc_location: strand.location
      )
      create(
        :shared_library_activity,
        activity: non_approved_igc,
        is_shared: false,
        school: course_template.school,
        source_activity: non_approved_igc
      )

      other_school_approved_igc = create(
        :instructor_created_activity,
        concept: concept,
        lesson: lesson,
        toc_location: strand.location
      )
      create(
        :shared_library_activity,
        activity: other_school_approved_igc,
        is_shared: true,
        school: other_school,
        source_activity: other_school_approved_igc
      )

      approved_igc = create(
        :instructor_created_activity,
        concept: concept,
        lesson: lesson,
        toc_location: strand.location
      )
      create(
        :shared_library_activity,
        activity: approved_igc,
        is_shared: true,
        school: course_template.school,
        source_activity: approved_igc
      )

      new_course_id = described_class.new(params).create_course

      results = CourseLibraryActivity.where(course_id: new_course_id).map do |entry|
        [entry.activity_id, entry.hidden]
      end

      expect(results).to eq([[approved_igc.id, true]])
    end
  end
end
