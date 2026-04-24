feature 'Gradebook Storage Navigation',
          chrome: true, js: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers

  let(:instructor) { create(:instructor) }
  let(:program) { create(:program_with_toc_entries) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:category) { create(:category, course: course) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:strand) { lesson.toc_entries.first }
  let(:lesson) { program.lessons.first }
  
  let(:concept) do
    create(
      :concept,
      id: strand.location,
      name: strand.title,
      program_id: program.id,
      lesson: lesson
    )
  end

  let(:activity) do
    create(
      :activity,
      lesson: lesson,
      concept: concept,
      toc_location: lesson.strands.first.location
    )
  end

  let!(:assignment) do
    create(
      :assignment,
      assignable: activity,
      section: section,
      category: category,
      due_date: course.start_date
    )  
  end

  before do
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)

    visit gradebook_engine.course_section_scores_path(
      program.id,
      course.id,
      section_id: section.id,
      lesson_or_due_date: 'lesson',
      all_lesson_or_week: 'section',
      activities_strand_or_day: 'activity',
      category_id: nil
    )
  end

  def revisit_gradebook 
    visit instructor_program_resources_path(program) 
    visit gradebook_engine.course_section_scores_path(
      program.id,
      course.id,
      section_id: section.id
    ) 
  end

  scenario 'As an instructor, I see the selected category when revisiting the gradebook' do
    select("#{category.name} (#{category.weighting_percent.round(0)}%)", from: 'category_id')
    revisit_gradebook
    expect(find('#category_id').value).to eq(category.id.to_s)
  end

  describe 'As an instructor when lesson filter selected' do
    before { select('Lesson', from: 'lesson_or_due_date') }

    scenario 'I see the lesson filter selected' do
      revisit_gradebook
      expect(find('#lesson_or_due_date').value).to eq('lesson')
    end

    scenario 'I see the selected lesson' do
      select(lesson.name, from: 'all_lesson_or_week')
      revisit_gradebook
      expect(find('#lesson_or_due_date').value).to eq('lesson')
      expect(find('#all_lesson_or_week').value).to eq(lesson.id.to_s)
    end

    scenario 'I see the selected activity' do
      select(lesson.name, from: 'all_lesson_or_week')
      select(activity.strand.title, from: 'activities_strand_or_day')
      revisit_gradebook
      expect(find('#lesson_or_due_date').value).to eq('lesson')
      expect(find('#all_lesson_or_week').value).to eq(lesson.id.to_s)
      expect(find('#activities_strand_or_day').value).to eq(activity.toc_location.to_s)
    end
  end

  describe 'As an instructor when the due date filter is selected' do
    around do |example|
      default_beginning_of_week = Date.beginning_of_week
      Date.beginning_of_week = :sunday
      example.run
      Date.beginning_of_week = default_beginning_of_week
    end

    before { select('Due Date', from: 'lesson_or_due_date') }

    scenario 'I see due date filter selected' do
      revisit_gradebook
      expect(find('#lesson_or_due_date').value).to eq('week')
    end

    context 'When first week selected' do
      let(:assignment_start_week) { assignment.due_date.beginning_of_week }
      let(:label_date_format) { '%-m/%-d/%y' }
      let(:value_date_format) { '%Y-%m-%d' }
      let(:option_start_date) { assignment_start_week.strftime(label_date_format) }
      let(:option_end_date) { assignment.due_date.end_of_week.strftime(label_date_format) }
      let(:selected_week) { "Week 1: #{option_start_date} - #{option_end_date}" }

      scenario 'I see selected week' do
        select(selected_week, from: 'all_lesson_or_week')
        revisit_gradebook
        expect(find('#all_lesson_or_week').value)
          .to eq(assignment_start_week.strftime(value_date_format))
      end

      scenario 'I see selected day' do
        select(selected_week, from: 'all_lesson_or_week')
        select(assignment.due_date.strftime(label_date_format), from: 'activities_strand_or_day')
        revisit_gradebook
        expect(find('#activities_strand_or_day').value)
          .to eq(assignment.due_date.strftime(value_date_format))
      end 
    end
  end
end
