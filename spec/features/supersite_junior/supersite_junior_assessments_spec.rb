feature 'Supersite Junior Assessments View', js: true, chrome: true do
  include RspecJsApiHelpers
  include RspecJsCommonHelpers
  include RspecJsContentHelpers

  let(:program) { create(:ss_jr_program) }
  let(:school) { create(:school) }
  let(:student) { create(:student) }
  let(:instructor) { create(:instructor, schools: [school]) }
  let(:units) { create_list(:unit_with_lessons_with_assessment_toc_entries, 4, program: program) }
  let(:lessons) { units.map { |u| u.lessons[0] } }
  let(:course) { create(:course, owner: instructor, program: program, school: school) }
  let(:category) { create(:category, course: course) }
  let(:section) do
    create(
      :section,
      due_time: DateTime.civil(2011, 1, 1, 23, 59),
      instructor: instructor,
      course: course
    )
  end
  let(:due_dates) { (1..4).map { |i| (i * 2).days.from_now.to_date } }

  let(:activities) do
    (0..3).map do |i|
      create_assessment(
        title: "activity_#{i}",
        points_possible: 10,
        lesson: lessons[0]
      )
    end
  end

  def student_assessments_url
    jr_section_assessments_path(course_id: course.id, section_id: section.id)
  end

  def create_concept_for_toc_entries(lesson)
    lesson.strands.each_with_index do |strand, index|
      create_concept_matching_strand_id(
        strand,
        name: strand.title,
        rank: index,
        assessment: true,
        lesson: lesson,
        program: program
      )
    end
  end

  def create_assignment(activity, attrs)
    create(
      :assignment,
      {
        assignable: activity,
        category: category,
        show_at: Date.today - 2.days
      }.merge(attrs)
    )
  end

  def create_assigned_assessment(assignment, attrs = {})
    create(
      :assigned_assessment_detail,
      assignment: assignment,
      time_limit: attrs[:time_limit],
      number_of_attempts: attrs[:number_of_attempts],
      password: attrs[:password]
    )
  end

  def create_assessment(attrs = {})
    strand = attrs[:lesson].toc_entries.first
    concept = create_concept_matching_strand_id(
      strand, attrs.slice(:lesson, :program)
    )
    create(
      :activity,
      {
        toc_location: strand.location,
        activity_type: 'exam',
        grading_method: 'mixed',
        concept: concept,
        randomizable: false
      }.merge(attrs)
    )
  end

  def to_do_due_date_time(due_date)
    due_date_time = Time.use_zone(section.time_zone) do
      Time.zone.local(
        due_date.year, due_date.month, due_date.day, 23, 59
      )
    end
    "Due #{due_date_time.to_s(:short_ordinal)}"
  end

  before do
    create(:active_enrollment, section: section, user: student)
    initialize_program_access_client_calls_for_user_and_program(student, program)
    give_user_access_to_program(student, program)
    log_in_as(student)
  end

  scenario 'As a student visiting the assessments view in a SS Jr program' do
    visit student_assessments_url

    expect(page).to have_content('Hooray!')
    expect(page).to have_content('You have no assessments.')

    expect(page).to have_no_selector('.test-assessment-to-do-list')
    expect(page).to have_no_selector('.test-assessment-finished-list')

    expect(page).to have_no_selector('.test-assessment-workset-0')
    expect(page).to have_no_selector('.test-assessment-0')

    step 'set up assigned assessments' do
      units.each do |unit|
        lesson = unit.lessons.first
        create_concept_for_toc_entries(lesson)
      end

      (0..3).each do |i|
        create_assignment(
          activities[i],
          due_date: due_dates[i],
          section: section,
          grade_availability: :on_grading
        ).tap do |assignment|
          create_assigned_assessment(
            assignment,
            time_limit: 150,
            number_of_attempts: 2,
            password: 'password'
          )
        end
      end
    end

    visit student_assessments_url

    expect(page).to have_no_content('Hooray!')
    expect(page).to have_no_content('You have no assessments.')

    within('.test-assessment-to-do-list') do
      expect(page).to have_selector('.test-assessment-workset-0')
      expect(page).to have_selector('.test-assessment-workset-1')
      expect(page).to have_selector('.test-assessment-workset-2')
      expect(page).to have_selector('.test-assessment-workset-3')
    end

    expect(page).to have_no_selector('.test-assessment-finished-list')

    step 'Complete the first two assessments.' do
      activities[0..1].each do |activity|
        create(:attempt_completed, activity: activity, section: section, user: student)
      end
    end

    purpose 'I can see both to-do and finished assessments' do
      visit student_assessments_url

      expect(page).to have_no_content('Hooray!')
      expect(page).to have_no_content('You have no assessments.')

      step 'to-do assignments appear in expected order with expected text' do
        within('.test-assessment-to-do-list') do
          within('.test-assessment-workset-0') do
            expect(page).to have_selector(
              '.test-due-date',
              text: to_do_due_date_time(due_dates[2])
            )
            expect(page).to have_selector(
              '.test-full-title',
              text: "#{lessons[2].name}|#{activities[2].concept_name}"
            )
          end

          within('.test-assessment-workset-1') do
            expect(page).to have_selector(
              '.test-due-date',
              text: to_do_due_date_time(due_dates[3])
            )
            expect(page).to have_selector(
              '.test-full-title',
              text: "#{lessons[3].name}|#{activities[3].concept_name}"
            )
          end
        end

        within('.test-assessment-finished-list') do
          within('.test-assessment-0') do
            expect(page).to have_selector(
              '.test-assessment-link',
              text: "#{lessons[0].name} | #{activities[0].concept_name}"
            )
            expect(page).to have_selector(
              '.test-due-date',
              text: due_dates[0].strftime('%a %-m/%-d')
            )
          end

          within('.test-assessment-1') do
            expect(page).to have_selector(
              '.test-assessment-link',
              text: "#{lessons[1].name} | #{activities[1].concept_name}"
            )
            expect(page).to have_selector(
              '.test-due-date',
              text: due_dates[1].strftime('%a %-m/%-d')
            )
          end
        end
      end
    end

    step 'Complete the last two assessments.' do
      activities[2..3].each do |activity|
        create(:attempt_completed, activity: activity, section: section, user: student)
      end
    end

    visit student_assessments_url

    expect(page).to have_no_content('Hooray!')
    expect(page).to have_no_content('You have no assessments.')

    within('.test-assessment-to-do-list') do
      expect(page).to have_content('You finished all your assessments')
    end

    within('.test-assessment-finished-list') do
      expect(page).to have_selector('.test-assessment-0')
      expect(page).to have_selector('.test-assessment-1')
      expect(page).to have_selector('.test-assessment-2')
      expect(page).to have_selector('.test-assessment-3')
    end
  end
end
