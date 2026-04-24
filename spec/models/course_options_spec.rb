describe CourseOptions do
  include DateTimeHelper

  let(:school) { FactoryBot.build_stubbed(:school) }
  let(:instructor) { FactoryBot.build_stubbed(:instructor) }
  let(:program) { build_stubbed(:program) }
  let(:unit) { build_stubbed(:unit, program: program) }
  let(:course) { build_stubbed(:course, program: program) }
  let(:level) { double('CoursePackage', content_type: 'level') }
  let(:component) { double('CoursePackage', content_type: 'component') }
  let(:course_options) { CourseOptions.new(instructor, course, program, school.id) }
  let(:course_options_no_school) { CourseOptions.new(instructor, course, program) }

  before do
    allow(program).to receive(:units).and_return([unit])
    allow(School).to receive(:find).and_return(school)
  end

  describe '#units' do
    it 'returns the program units' do
      expect(course_options.units).to match_array([unit])
    end
  end

  describe '#levels' do
    it 'returns level course packages for the program' do
      expect(Maestro::CoursePackage).to receive(:all)
        .with(program.id).and_return([level, component])
      expect(course_options.levels).to eq([level])
    end

    describe 'when there are no levels' do
      it 'returns an empty array' do
        expect(Maestro::CoursePackage).to receive(:all)
          .with(program.id).and_return([])
        expect(course_options.levels).to eq([])
      end
    end
  end

  describe '#components' do
    it 'returns component course packages for the program' do
      expect(Maestro::CoursePackage).to receive(:all)
        .with(program.id).and_return([level, component])
      expect(course_options.components).to eq([component])
    end

    describe 'when there are no components' do
      it 'returns an empty array' do
        expect(Maestro::CoursePackage).to receive(:all)
          .with(program.id).and_return([])
        expect(course_options.components).to eq([])
      end
    end
  end

  describe '#basic_category' do
    it 'returns a category for the basic course settings' do
      allow(ScoringRuleset).to receive(:new_course_defaults).and_return('scoring_ruleset')
      expected = {
        name: 'Homework',
        weighting_percent: 100,
        credit_only: false,
        max_attempts: 2,
        enhanced_feedback_disabled: false,
        accept_late_work: true,
        late_work_penalty: 'percent_per_day',
        penalty_percent: 5,
        rank: 1,
        scoring_rulesets_attributes: ['scoring_ruleset']
      }
      expect(course_options.basic_category).to eq(expected)
    end
  end

  describe '#default_courses', test_debt: true do
    it 'returns a course default settings and a basic course' do
      course = build_stubbed(:course)
      default_course = build_stubbed(:course)
      basic_course = build_stubbed(:course)
      course_options = CourseOptions.new(instructor, course, program)
      allow(course_options).to receive(:basic_category).and_return('category')

      Timecop.freeze do
        expect(Course).to receive(:new)
          .with(school_id: school.id,
                name: 'Default settings',
                first_unit: program.units.first,
                last_unit: program.units.last,
                end_date: 14.weeks.from_now,
                start_date: Time.zone.now)
          .and_return(default_course)

        expect(Course).to receive(:new)
          .with(school_id: school.id,
                name: 'Basic course',
                first_unit: program.units.first,
                last_unit: program.units.last,
                end_date: 14.weeks.from_now,
                start_date: Time.zone.now,
                categories_attributes: ['category'])
          .and_return(basic_course)

        expect(course_options.default_courses).to eq([default_course, basic_course])
      end
    end
  end

  describe '#previous_courses' do
    it 'returns a sorted array of previous courses' do
      prev_course_1 = create(:course, start_date: Date.today, name: 'A', owner: instructor, program: program)
      prev_section_1 = create(:section, course_id: prev_course_1.id, instructor: instructor)
      prev_course_2 = create(:course, start_date: Date.yesterday, name: 'B', owner: instructor, program: program)
      prev_section_2 = create(:section, course_id: prev_course_2.id, instructor: instructor)
      prev_course_3 = create(:course, start_date: Date.yesterday, name: 'A', owner: instructor, program: program)
      prev_section_3 = create(:section, course_id: prev_course_3.id, instructor: instructor)
      expect(course_options.previous_courses).to eq([prev_course_3, prev_course_2, prev_course_1])
    end

    it 'returns courses that have sections with the instructor in the instructor team' do
      prev_course_1 = create(:course, start_date: Date.yesterday, name: 'A', owner: instructor, program: program)
      create(:section, course_id: prev_course_1.id, instructor: instructor)
      expect(course_options.previous_courses).to eq [prev_course_1]
    end

    it 'does not return courses that have no sections with the instructor in the instructor team' do
      prev_course_1 = create(:course, start_date: Date.yesterday, name: 'A', owner: instructor, program: program)
      instructor_2 = build_stubbed(:instructor)
      create(:section, course_id: prev_course_1.id, instructor: instructor_2)
      expect(course_options.previous_courses).to eq []
    end

    it 'includes all section instructors for all the returned sections' do
      prev_course_1 = create(:course, start_date: Date.yesterday, name: 'A', owner: instructor, program: program)
      instructor_2 = build_stubbed(:instructor)
      instructor_3 = build_stubbed(:instructor)
      section_1 = create(:section_without_section_instructor_callback, course_id: prev_course_1.id)
      si_1 = create(:section_instructor, section: section_1, instructor: instructor)
      si_2 = create(:section_instructor, section: section_1, instructor: instructor_2)
      si_3 = create(:section_instructor, section: section_1, instructor: instructor_3)
      expect(course_options.previous_courses.first.sections.first.section_instructors).to eq [si_1, si_2, si_3]
    end

    it 'does not return course templates' do
      prev_course_1 = create(:course, start_date: Date.yesterday, name: 'A', owner: instructor, program: program)
      create(:section, course_id: prev_course_1.id, instructor: instructor)
      course_template = create(:course,
                               is_template: true,
                               owner: instructor,
                               program: program,
                               start_date: Date.yesterday)
      create(:section, course_id: course_template.id, instructor: instructor)
      expect(course_options.previous_courses).to eq [prev_course_1]
    end
  end

  describe '#previous_course_templates' do
    it 'returns a sorted array of previous course templates' do
      prev_ctmpl_1 = create(:course_template, start_date: Date.today, name: 'A', program: program, school: school)
      create(:section, course_id: prev_ctmpl_1.id)
      prev_ctmpl_2 = create(:course_template, start_date: Date.yesterday, name: 'B', program: program, school: school)
      create(:section, course_id: prev_ctmpl_2.id)
      prev_ctmpl_3 = create(:course_template, start_date: Date.yesterday, name: 'A', program: program, school: school)
      create(:section, course_id: prev_ctmpl_3.id)
      expect(course_options.previous_course_templates).to eq([prev_ctmpl_3, prev_ctmpl_2, prev_ctmpl_1])
    end

    it 'returns course templates for the school and program only' do
      prev_ctmpl_1 = create(:course_template, start_date: Date.today, name: 'A', program: program, school: school)
      create(:section, course_id: prev_ctmpl_1.id)

      prev_ctmpl_other_program = create(:course_template, start_date: Date.today, name: 'A', school: school)
      create(:section, course_id: prev_ctmpl_other_program.id)

      prev_ctmpl_other_school = create(:course_template, start_date: Date.today, name: 'A', program: program)
      create(:section, course_id: prev_ctmpl_other_school.id)

      expect(course_options.previous_course_templates).to eq([prev_ctmpl_1])
    end

    it 'raises an error if no school is selected' do
      prev_ctmpl_1 = create(:course_template, start_date: Date.today, name: 'A', program: program, school: school)
      create(:section, course_id: prev_ctmpl_1.id)

      expect(course_options_no_school.previous_course_templates).to be_empty
    end

    it 'does not return regular courses' do
      prev_ctmpl_1 = create(:course_template, start_date: Date.today, name: 'A', program: program, school: school)
      create(:section, course_id: prev_ctmpl_1.id)
      prev_course_1 = create(:course, start_date: Date.today, name: 'A', owner: instructor, program: program, school: school)
      create(:section, course_id: prev_course_1.id, instructor: instructor)
      expect(course_options.previous_course_templates).to eq([prev_ctmpl_1])
    end
  end

  describe '#previous_courses_with_assignments' do
    let(:instructor_2) { create(:instructor) }
    let(:assignment_1) { create(:assignment) }
    let(:assignment_2) { create(:assignment) }
    let(:assignment_3) { create(:assignment) }
    let(:assignment_4) { create(:assignment) }
    let(:assignment_5) { create(:assignment) }

    let(:course_1) do
      create(:course, start_date: Time.zone.today, name: 'A', owner: instructor, program:)
    end

    let(:section_1) do
      create(:section, course: course_1, instructor:, assignments: [assignment_1])
    end

    # courses with neither assignments or external items are not included
    let(:course_2) do
      create(:course, start_date: Time.zone.today, name: 'B', owner: instructor, program:)
    end

    let(:section_2) do
      create(:section, course: course_2, instructor:, assignments: [])
    end

    let(:course_3) do
      create(:course, start_date: Time.zone.today, name: 'C', owner: instructor_2, program:)
    end

    let(:section_3) do
      create(:section, course: course_3, instructor: instructor_2, assignments: [assignment_2])
    end

    let(:course_4) do
      create(
        :course,
        start_date: Time.zone.yesterday,
        name: 'D',
        owner: instructor,
        program:
      )
    end

    let(:section_4) do
      create(:section, course: course_4, instructor:, assignments: [assignment_3])
    end

    # check that course templates aren't included
    let(:course_5) do
      create(
        :course,
        is_template: true,
        start_date: Time.zone.yesterday,
        name: 'E',
        owner: instructor,
        program:
      )
    end

    let(:section_5) do
      create(:section, course: course_5, instructor:, assignments: [assignment_4])
    end

    # Courses with only external items are included
    let(:course_6) do
      create(:course, start_date: Time.zone.today, name: 'F', owner: instructor, program:)
    end

    let(:section_6) { create(:section, course: course_6, instructor:, assignments: []) }

    # Enterprise Courses owned by the instructor are included
    let(:enterprise_course) do
      create(:enterprise_course, start_date: Time.zone.today, name: 'G', owner: instructor, program:)
    end

    let(:section_7) do
      create(:section, course: enterprise_course, instructor:, assignments: [assignment_5])
    end
    let(:external_activity) { instance_double(GradebookEngine::ExternalActivity, id: 1, name: 'F') }

    let(:external_assignment) do
      instance_double(
        GradebookEngine::ExternalAssignment,
        day_id: Time.zone.today,
        external_activity:,
        section: section_6
      )
    end

    let(:expected_items) do
      [
        {
          id: external_activity.id,
          day_id: external_assignment.day_id,
          name: external_activity.name
        }
      ]
    end

    before do
      create(:section_instructor, section: section_3, instructor:, role: 'Co-instructor')
      allow(GradebookEngine::GradebookAPI).to receive(:find_external_items_by_section)
        .with(section_1.id)
        .and_return([])

      allow(GradebookEngine::GradebookAPI).to receive(:find_external_items_by_section)
        .with(section_2.id)
        .and_return([])

      allow(GradebookEngine::GradebookAPI).to receive(:find_external_items_by_section)
        .with(section_3.id)
        .and_return([])

      allow(GradebookEngine::GradebookAPI).to receive(:find_external_items_by_section)
        .with(section_4.id)
        .and_return([])

      allow(GradebookEngine::GradebookAPI).to receive(:find_external_items_by_section)
        .with(section_5.id)
        .and_return([])

      allow(GradebookEngine::GradebookAPI).to receive(:find_external_items_by_section)
        .with(section_6.id)
        .and_return(expected_items)

      allow(GradebookEngine::GradebookAPI).to receive(:find_external_items_by_section)
        .with(section_7.id)
        .and_return([])
    end

    it 'returns previous courses and Enterprise courses with assignments or ' \
       'external items through sections instructed or co-instructed by the instructor' do
      expect(course_options.previous_courses_with_assignments).to match_array(
        [course_4, course_1, course_3, course_6, enterprise_course]
      )
    end
  end

  describe '#section_for_course' do
    it 'returns instructed and co-instructed sections for a user given a course' do
      instructor_2 = create(:instructor)
      assignment_1 = create(:assignment)
      assignment_2 = create(:assignment)
      assignment_3 = create(:assignment)
      assignment_4 = create(:assignment)
      course_1 = create(:course, start_date: Date.today, name: 'A', owner: instructor, program: program)
      section_1 = create(:section, name: 'B', course: course_1, instructor: instructor, assignments: [assignment_1])
      section_2 = create(:section, name: 'A', course: course_1, instructor: instructor, assignments: [assignment_2])
      course_3 = create(:course, start_date: Date.today, name: 'B', owner: instructor_2, program: program)
      section_3 = create(:section, name: 'A', course: course_3, instructor: instructor_2, assignments: [assignment_3])
      section_4 = create(:section, name: 'B', course: course_3, instructor: instructor_2, assignments: [assignment_4])
      create(:section_instructor, section: section_3, instructor: instructor, role: 'Co-instructor')
      create(:section_instructor, section: section_4, instructor: instructor, role: 'Co-instructor')
      expect(course_options.sections_for_course(course_1.id)).to eq([section_2, section_1])
      expect(course_options.sections_for_course(course_3.id)).to eq([section_3, section_4])
    end

    describe 'when course has only external items' do
      let(:course) do
        create(:course, start_date: Time.zone.today, name: 'A', owner: instructor, program: program)
      end

      let(:section) do
        create(:section, course: course, instructor: instructor, assignments: [])
      end

      let(:external_activity) do
        instance_double(GradebookEngine::ExternalActivity, id: 1, name: 'A')
      end

      let(:external_assignment) do
        instance_double(
          GradebookEngine::ExternalAssignment,
          day_id: Time.zone.today,
          external_activity: external_activity,
          section: section
        )
      end

      let(:expected_items) do
        [
          {
            id: external_activity.id,
            day_id: external_assignment.day_id,
            name: external_activity.name
          }
        ]
      end

      before do
        allow(GradebookEngine::GradebookAPI).to receive(:find_external_items_by_section)
          .with(section.id)
          .and_return(expected_items)
      end

      it 'returns instructed and co-instructed sections for a user given a course' do
        expect(course_options.sections_for_course(course.id)).to eq([section])
      end
    end

    it 'returns an empty array when there are no sections for a course' do
      expect(course_options.sections_for_course(100)).to eq([])
    end
  end

  describe '#preview_sections_by_school' do
    it 'returns existing sections and a preview section grouped by school id' do
      existing_section = build_stubbed(:section)
      preview_section = build_stubbed(:section)
      school = build_stubbed(:school)
      expected = { school.id => [preview_section, existing_section] }

      expect(Section).to receive(:new)
        .with(instructor: instructor,
              instructors: [instructor],
              course: course).and_return(preview_section)
      allow(instructor).to receive(:schools).and_return([school])
      allow(instructor).to receive(:sections_grouped_by_school_id)
        .and_return(school.id => [existing_section])

      expect(course_options.preview_sections_by_school).to eq(expected)
    end
  end

  describe '#course_packages_by_course' do
    it 'returns course packages grouped by course' do
      expect(Maestro::CoursePackage).to receive(:all_for_courses)
        .with([course.guid]).and_return(course.guid => [level, component])

      expect(course_options.course_packages_by_course).to eq({
        course.id => {
          'level' => [level],
          'component' => [component]
        }
      })
    end
  end

  context 'when getting available course packages or their data' do
    let(:level_package) do
      {
        "id"=>203,
        "program_id"=>145,
        "name"=>"Supersite",
        "rank"=>1,
        "content_type"=>"level",
        "license_groups"=>
          [
            {"id"=>4, "name"=>"00-Media_Only"},
            {"id"=>1, "name"=>"01-Supersite"}
          ],
        "available_license_groups"=>[],
        "package_type"=>nil
      }
    end
    let(:component_package) do
      {
        "id"=>205,
        "program_id"=>145,
        "name"=>"WebSAM (online Student Activities Manual)",
        "rank"=>1,
        "content_type"=>"component",
        "license_groups"=>
          [
            {"id"=>3, "name"=>"WebSAM"}
          ],
        "available_license_groups"=>[],
        "package_type"=>nil
      }
    end

    before do
      allow(course_options).to receive(:default_school).and_return(school)
    end

    shared_context 'when course packages are available' do
      before do
        allow(Maestro::CoursePackage).to receive(:available_packages)
          .with(program.id, school.guid, nil)
          .and_return([level_package, component_package])
      end
    end

    shared_context 'when course packages are not available' do
      before do
        allow(Maestro::CoursePackage).to receive(:available_packages)
          .with(program.id, school.guid, nil)
          .and_return([])
      end
    end

    describe '#available_course_packages' do
      context 'when there are available course packages' do
        include_context 'when course packages are available'

        it 'returns the available course packages' do
          expect(course_options.available_course_packages).to eq(
            [level_package, component_package]
          )
        end
      end

      context 'when there are no available course packages' do
        include_context 'when course packages are not available'

        it 'returns nil' do
          expect(course_options.available_course_packages).to be_nil
        end
      end
    end

    describe '#available_course_package_ids' do
      context 'when there are available course packages' do
        include_context 'when course packages are available'

        it 'returns the available course package IDs' do
          expect(course_options.available_course_package_ids).to eq(
            [level_package['id'], component_package['id']]
          )
        end
      end

      context 'when there are no available course packages' do
        include_context 'when course packages are not available'

        it 'returns an empty array' do
          expect(course_options.available_course_package_ids).to eq([])
        end
      end
    end
  end

  describe '#categories_with_assessment_count_for_course' do
    let(:category) { build_stubbed(:category, course: course) }

    before do
      allow(course_options).to receive(:previous_courses).and_return([course])
      allow(Category).to receive(:with_assessment_count).and_return([category])
    end

    context 'when there is a category for the given course' do
      it 'returns the categories for that course' do
        expect(course_options.categories_with_assessment_count_for_course(course)).to eq([category])
      end
    end

    context 'when the course has no categories' do
      it 'returns an empty array' do
        expect(course_options.categories_with_assessment_count_for_course(build_stubbed(:course))).to eq([])
      end
    end
  end

  describe '#scoring_ruleset_by_id' do
    let(:prev_course) { create(:course, owner: instructor, program: program) }
    let(:prev_course_template) do
      create(
        :course,
        is_template: true,
        owner: instructor,
        program: program
      )
    end
    let(:course_category) { create(:category, course: prev_course) }
    let(:template_category) { create(:category, course: prev_course_template) }

    let(:course_scoring_ruleset) { create(:scoring_ruleset, category: course_category) }
    let(:template_scoring_ruleset) { create(:scoring_ruleset, category: template_category) }

    before do
      allow(instructor).to receive(:editable_courses_by_program).and_return([prev_course])
      allow(course_options).to receive(:previous_course_templates).and_return(
        [prev_course_template]
      )
    end

    context 'when the given course`s scoring ruleset id exists' do
      it 'returns the ruleset object' do
        expect(course_options.scoring_ruleset_by_id(course_scoring_ruleset.id)).to eq(
          course_scoring_ruleset
        )
      end
    end

    context 'when the given course template`s scoring ruleset id exists' do
      it 'returns the ruleset object' do
        expect(course_options.scoring_ruleset_by_id(template_scoring_ruleset.id)).to eq(
          template_scoring_ruleset
        )
      end
    end

    context 'when scoring_ruleset_by_id is called multiple times' do
      it 'look up scoring rulesets only once' do
        allow(ScoringRuleset).to receive(:joins).and_call_original
        course_options.scoring_ruleset_by_id(course_scoring_ruleset.id)
        course_options.scoring_ruleset_by_id(course_scoring_ruleset.id)
        expect(ScoringRuleset).to have_received(:joins).exactly(1).time
      end
    end

    context 'when the given scoring ruleset id does not exists exists' do
      it 'returns the default ruleset' do
        default_ruleset = double(ScoringRuleset)
        allow(ScoringRuleset).to receive_message_chain(:default, :dup).and_return(default_ruleset)
        expect(course_options.scoring_ruleset_by_id(nil)).to eq(default_ruleset)
      end
    end
  end

  describe '#previous_course_and_section_data' do
    it 'returns previous-course data by default' do
      course_with_section = create(:course_with_section)
      section = course_with_section.sections.first
      allow(CourseTimeCalculator).to receive(:formatted_time)
        .with(course_with_section).and_return({ weeks: "1 week", days: "0 days" })
      allow(course_options).to receive(:previous_courses_with_assignments)
        .and_return([course_with_section])
      allow(course_options).to receive(:sections_for_course)
        .and_return([section])
      expect(course_options.previous_course_and_section_data)
        .to eq([{
          id: course_with_section.id,
          name: course_with_section.name,
          weeks: "1 week",
          enterprise: course_with_section.is_enterprise,
          template: course_with_section.is_template,
          sections: [{
            id: course_with_section.sections.first.id,
            class_days_count: course_with_section.sections.first.class_days.split(',').count,
            name: course_with_section.sections.first.name
          }]
        }])
    end
  end

  context '#previous_enterprise_courses_with_assignments' do
    let(:instructor) { create(:instructor) }
    let(:program) { create(:program) }

    let(:enterprise_section_1) { create(:enterprise_section, assignments: [create(:assignment)]) }
    let(:enterprise_section_2) { create(:enterprise_section, assignments: [create(:assignment)]) }

    let(:enterprise_course_1) do
      create(
        :enterprise_course,
        program:,
        start_date: Date.today,
        name: 'A',
        enterprise_section: enterprise_section_1
      )
    end

    let!(:enterprise_course_2) do
      create(
        :enterprise_course,
        program:,
        school_id: enterprise_course_1.school_id,
        start_date: Date.yesterday,
        name: 'B',
        enterprise_section: enterprise_section_2
      )
    end

    let(:enterprise_course_no_assignments) do
      create(
        :enterprise_course,
        program:,
        start_date: Date.today,
        name: 'C',
        enterprise_section: create(:enterprise_section, assignments: [])
      )
    end

    let(:enterprise_course_no_section) do
      create(:enterprise_course, program:, start_date: Date.today, name: 'D')
    end

    let(:course_options) { described_class.new(instructor, enterprise_course_1, program) }

    context 'when the enterprise course has assignments in its section' do
      let(:result) { course_options.previous_enterprise_courses_with_assignments }

      it 'includes all the enterprise courses excluding itself in the result' do
        expect(result.map(&:id)).to include(enterprise_course_2.id)
      end

      it 'excludes itself in the result' do
        expect(result.map(&:id)).not_to include(enterprise_course_1.id)
      end

      it 'does not include enterprise courses from other schools' do
        enterprise_course_3 = create(
          :enterprise_course,
          program:,
          start_date: Date.yesterday,
          name: 'B',
          enterprise_section: enterprise_section_2
        )
        expect(result.map(&:school_id).uniq).not_to include(enterprise_course_3.school_id)
      end
    end

    context 'when the enterprise course has no assignments or external items' do
      it 'excludes the enterprise course from the result' do
        result = course_options.previous_enterprise_courses_with_assignments
        expect(result.map(&:id)).not_to include(enterprise_course_no_assignments.id)
      end
    end

    context 'when the enterprise course has no section' do
      it 'excludes the enterprise course from the result' do
        result = course_options.previous_enterprise_courses_with_assignments
        expect(result.map(&:id)).not_to include(enterprise_course_no_section.id)
      end
    end
  end
end
