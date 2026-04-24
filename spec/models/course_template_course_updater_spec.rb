describe CourseTemplateCourseUpdater do
  let(:name) { 'New course name' }
  let(:course_template) { create(:course_template) }
  let(:other_course_template) { create(:course_template) }
  let(:instructor) { create(:instructor) }
  let(:other_instructor) { create(:instructor) }

  let(:course) do
    create(:course,
           owner_id: instructor.id,
           source_template_id: course_template.id,
           hide_from_instructor_dashboard: false)
  end

  let(:section_1) { create(:section, course: course) }
  let(:section_2) { create(:section, course: course) }

  let!(:section_1_instructor) do
    create(:section_instructor,
           instructor: instructor,
           role: 'Instructor',
           section: section_1)
  end

  let!(:section_2_instructor) do
    create(:section_instructor,
           instructor: instructor,
           role: 'Instructor',
           section: section_2)
  end

  let(:section_1_assistant) do
    create(:section_instructor,
           instructor: other_instructor,
           role: 'Assistant',
           section: section_1)
  end

  let(:section_2_coinstructor) do
    create(:section_instructor,
           instructor: other_instructor,
           role: 'Co-instructor',
           section: section_2)
  end

  let(:course_from_query) do
    Course.find(course.id)
  end

  describe '#initialize' do
    it 'raises an error if course does not exist' do
      params = {
        course_id: course.id + 1,
        name: name,
        owner_id: instructor.id,
        source_template_id: course_template.id
      }

      expect { described_class.new(params) }.to raise_error(
        "There is no course with id = #{course.id + 1}."
      )
    end
  end

  describe '#update_course' do
    it 'updates name, owner, source template and hide from dash checkbox status on the course record' do
      described_class.new(
        course_id: course.id,
        hide_from_dash_checkbox_status: true,
        name: name,
        owner_id: other_instructor.id,
        source_template_id: other_course_template.id
      ).update_course

      expect(course_from_query.name).to eq(name)
      expect(course_from_query.owner).to eq(other_instructor)
      expect(course_from_query.source_template_id).to eq(other_course_template.id)
      expect(course_from_query.hide_from_instructor_dashboard).to eq(true)
    end

    it 'creates section instructor records for new owner not yet associated with course' do
      described_class.new(
        course_id: course.id,
        hide_from_dash_checkbox_status: true,
        name: name,
        owner_id: other_instructor.id,
        source_template_id: other_course_template.id
      ).update_course

      section_instructors = SectionInstructor.where(instructor: other_instructor, role: 'Instructor')
      expect(section_instructors.count).to eq(2)
      expect(section_instructors.map(&:hide_from_instructor_dashboard).all?).to be(true)
    end

    it 'changes section-instructor roles for new owner if already associated with course' do
      # Associate other instructor with sections as additional instructor
      section_1_assistant
      section_2_coinstructor

      described_class.new(
        course_id: course.id,
        hide_from_dash_checkbox_status: true,
        name: name,
        owner_id: other_instructor.id,
        source_template_id: other_course_template.id
      ).update_course

      section_instructors = SectionInstructor.where(instructor: other_instructor, role: 'Instructor')
      expect(section_instructors.count).to eq(2)
      expect(section_instructors.map(&:hide_from_instructor_dashboard).all?).to be(true)
      expect(SectionInstructor.where(instructor: other_instructor, role: 'Assistant').count).to eq(0)
      expect(SectionInstructor.where(instructor: other_instructor, role: 'Co-instructor').count).to eq(0)
    end

    it 'removes section instructor records for old owner' do
      described_class.new(
        course_id: course.id,
        name: name,
        owner_id: other_instructor.id,
        source_template_id: other_course_template.id
      ).update_course

      expect(SectionInstructor.where(instructor: instructor).count).to eq(0)
    end

    it 'does not delete section instructor records if owner has not changed' do
      # Find the course owner's section-instructor record for the first section
      first_section = course.sections.first
      owner_si_record_1 = SectionInstructor.joins(:section)
                                              .where(section: first_section,
                                                     user_id: instructor.id)
                                              .first

      # Update the course, not changing the owner
      described_class.new(
        course_id: course.id,
        hide_from_dash_checkbox_status: true,
        name: name,
        owner_id: instructor.id,
        source_template_id: other_course_template.id
      ).update_course

      # Check that the updater didn't delete the old record and create a new one
      owner_si_record_2 = SectionInstructor.joins(:section)
                                            .where(section: first_section,
                                                   user_id: instructor.id)
                                            .first

      expect(owner_si_record_2.id).to eq(owner_si_record_1.id)

      # Check that the 'hide' flag is updated
      expect(owner_si_record_2.hide_from_instructor_dashboard).to be(true)
    end

    it 'updates the instructor_id on all sections to be for the new course owner' do
      described_class.new(
        course_id: course.id,
        name: name,
        owner_id: other_instructor.id,
        source_template_id: other_course_template.id
      ).update_course

      section_1.reload
      section_2.reload
      expect(section_1.instructor_id).to eq(other_instructor.id)
      expect(section_2.instructor_id).to eq(other_instructor.id)
    end
  end
end
