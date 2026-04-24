module GradebookEngineHelpers
  # Enable a temporary gradebook synchronization.
  # If he gradebook synchronization is already enabled, it'll raise an error.
  def with_new_gb_sync
    old_value = Rails.configuration.update_test_gradebook
    raise 'Gradebook synchronization already enabled' if old_value
    Rails.configuration.update_test_gradebook = true
    begin
      yield
    ensure
      Rails.configuration.update_test_gradebook = old_value
    end
  end

  # Some of these methods rely on variables set using `let` statements.

  # Data Setup Helpers

  def create_gradebook_engine_submission(submitted_at:, **attrs)
    activity_id = (attrs.delete(:activity) || activity).id
    student_id = (attrs.delete(:student) || student).id
    target_section = (attrs.delete(:section) || section)

    GradebookEngine::GradebookAPI.submit(
      student_id,
      target_section.id,
      activity_id,
      target_section.school_id,
      {
        attempt_count: 1,
        pending: true,
        points_earned: 0,
        submitted_at: submitted_at
      }.merge(attrs)
    )
  end

  def blank_open_ended_results(target_activity = nil)
    # Use activity from 'let' statement if none specified.
    target_activity ||= activity
    # The student left everything blank so they got 0 points.
    MaestroActivityEngine::ActivityContent::Results
      .new(target_activity.content_object).tap do |results|
      results.add(label: 'question_01', response: '')
      results.add(label: 'question_02', response: '')
      results.add(label: 'question_03', response: '')
      results.add(label: 'question_04', response: '')
    end
  end

  def blank_composition_results(target_activity = nil)
    # Use activity from 'let' statement if none specified.
    target_activity ||= activity
    # The student left everything blank so they got 0 points.
    MaestroActivityEngine::ActivityContent::Results
      .new(target_activity.content_object).tap do |results|
      results.add(label: 'question_1', response: '')
    end
  end

  # score_action helpers

  def latest_score_action(activity_id:, section_id:, user_id:)
    GradebookEngine::GradebookAPI.find_score(activity_id: activity_id,
                                             section_id: section_id,
                                             user_id: user_id)
  end

  # URL Helpers

  def activities_for_lesson_url
    gradebook_engine.course_section_scores_path(
      program.id,
      course.id,
      section_id: section.id,
      activities_strand_or_day: 'activity',
      lesson_or_due_date: 'lesson',
      all_lesson_or_week: lesson.id
    )
  end

  # CSS Selector Helpers

  def header_id(activity)
    if activity.is_a? GradebookEngine::ExternalActivity
      "th.test-ext_activity_#{activity.id}_header"
    else
      "th.test-activity_#{activity.id}_header"
    end
  end

  def column_header(activity)
    find(".js-gb-table-top #{header_id(activity)}")
  end

  def header_menu(activity)
    find(".js-gb-table-full #{header_id(activity)}")
  end

  def student_grade_selector(student_id = nil, activity_id = nil)
    # If arguments aren't specified, fall back to values obtained from
    # `let` statements.
    student_id ||= student.id
    activity_id ||= activity.id
    ".test-user_#{student_id}_grade_#{activity_id}"
  end

  def student_activity_grade_selector(student_id = nil, activity_id = nil)
    # If arguments aren't specified, fall back to values obtained from
    # `let` statements.
    student_id ||= student.id
    activity_id ||= activity.id
    ".c-table--assignment-grades .test-user_#{student_id}_grade_#{activity_id}.c-row--gradebook"
  end

  def open_selectbox_menu(field_id)
    find("##{field_id}").click
  end
  alias close_selectbox_menu open_selectbox_menu

  def selectbox_options(field_id)
    # open_selectbox_menu(field_id)
    all(
      "##{field_id} option"
    )
  end

  def choose_from_selectbox(field_id, option_text)
    # TODO: find the things that use this and change them to just
    # use the method implementation.
    select(option_text, from: field_id)
  end

  ## Expectation Helpers

  def csv_row_for_student(rows, student)
    rows.detect do |row|
      row.fetch('First Name') == student.first_name &&
        row.fetch('Last Name') == student.last_name
    end
  end

  def expect_cell(student_id, activity_id,
                  percent: nil,
                  points: nil,
                  late: nil,
                  partial_pending: false,
                  submitted: true)
    cell = find(student_grade_selector(student_id, activity_id))
    validate_percent(cell, percent) if percent
    validate_points(cell, points) if points
    validate_lateness(cell, late) unless late.nil?
    validate_partial_pending(cell, partial_pending)
    validate_submitted(cell, submitted)
  end

  def expect_flash_message(type, message)
    flash = find(".test-flash-#{type}")
    expect(flash).to be_visible
    expect(flash).to have_text(message)
  end

  def expect_flash(type, message)
    flash = find(".flash-#{type}")
    expect(flash).to have_text(message)
    expect(flash).to be_visible
  end

  def expect_student_score_cell(student_id, activity_id,
                                score: '',
                                points: '',
                                points_possible:,
                                attempts: '',
                                status: nil,
                                partial_pending: false)
    line = find(student_activity_grade_selector(student_id, activity_id))
    expected_score = if partial_pending
                       'Pending'
                     elsif score.is_a?(Float)
                       "#{score}%"
                     else
                       ''
                     end
    expect(line.find('td.c-row-head')).to have_text(expected_score, exact: true)
    cells = line.all('td.c-data-gb')
    expect(cells[0].text).to eq(points.to_s)
    expect(cells[1].text).to eq(points_possible.to_f.to_s)
    expect(cells[2].text).to eq(attempts.to_s)
    expect(cells[4]).to have_text(status)
    validate_partial_pending(line, partial_pending)
  end

  private def validate_percent(cell, expected_percent)
    percentage = cell.find('.js-percent').text
    # Calling .to_f strips out the % sign and any trailing spaces.
    # Only do this if expected_percent is a float so we support
    # values like 'Pending', '--', and checkmarks.
    percentage = percentage.to_f if expected_percent.is_a?(Float)
    expect(percentage).to eq(expected_percent)
  end

  private def validate_points(cell, expected_points)
    # Points field is usually hidden, by default, but we can still verify it
    # has the correct value using have_text(:all).
    points_span = cell.find('.js-points')
    expect(points_span).to have_text(:all, expected_points)
  end

  private def validate_lateness(cell, expected_lateness)
    expect(cell.has_css?('.js-late')).to eq(expected_lateness)
  end

  private def validate_partial_pending(cell, expected_partial_pending)
    if expected_partial_pending
      expect(cell.text).to include("Pending")
    end
  end

  private def validate_submitted(cell, expected_submitted)
    if expected_submitted
      expect(cell).to have_no_selector('span[title="Not submitted"]')
    else
      expect(cell).to have_selector('span[title="Not submitted"]')
    end
  end
end
