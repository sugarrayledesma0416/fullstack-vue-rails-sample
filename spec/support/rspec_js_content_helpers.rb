module RspecJsContentHelpers
  def create_activity_with_unit_lesson_and_concept(program, opts = {})
    create_activities_with_the_same_toc_location(program, 1, opts).first
  end

  def create_diagnostic_v2_activity_with_unit_lesson_and_concept(program, type = :summative, opts = {})
    create_activities_with_the_same_toc_location(program, 1, opts) do |attributes|
      if type == :summative
        create_summative_activity(program, attributes)
      elsif type == :formative
        create_formative_activity(program, attributes)
      end
    end.first
  end

  def activity_location_attributes(program, attrs = {})
    lesson = attrs.delete(:lesson) || find_or_create_first_lesson(program)
    strand = create_strand_in_lesson(lesson, attrs)
    concept = create_concept_matching_strand_id(strand, lesson: lesson, program: program)
    {
      concept: concept,
      lesson: lesson,
      toc_location: strand.location
    }
  end

  def assessment_location_attributes(program, attrs = {}, keep_toc_entries = false)
    lesson = attrs.delete(:lesson) || find_or_create_first_lesson(program)
    strand = create_strand_in_lesson(lesson, attrs.merge(assessment: true), keep_toc_entries)
    concept = create_concept_matching_strand_id(strand, lesson: lesson, program: program)
    {
      concept: concept,
      lesson: lesson,
      toc_location: strand.location
    }
  end

  def find_or_create_first_lesson(program)
    unit = program.units.first || create(:unit, program: program, rank: 1)
    unit.lessons.first || create(:lesson, unit: unit)
  end

  def create_strand_in_lesson(lesson, strand_attrs = {}, keep_toc_entries = false)
    strand_id = strand_attrs.delete(:strand_id)
    strand_attrs[:level] ||= 1
    existing = strand_id && lesson.strand(strand_id)
    return existing if existing

    create(:toc_entry, strand_attrs).tap do |strand|
      strand.location = strand_id.to_s if strand_id
      existing_toc_entries = keep_toc_entries ? lesson.toc_entries : []
      lesson.toc_entries = [*existing_toc_entries, strand]
      lesson.save!
    end
  end

  def create_concept_matching_strand_id(strand, concept_attrs)
    lesson = concept_attrs[:lesson]
    existing = Concept.where(id: strand.location).first
    raise 'Lesson mismatch' if existing && lesson && lesson.id != existing.lesson_id
    return existing if existing

    build(:concept, concept_attrs).tap do |concept|
      concept.assessment = strand.assessment?
      concept.singular_label = 'quiz' if strand.assessment?
      concept.id = strand.location
      concept.save!
    end
  end

  def create_summative_activity(program, opts = {})
    summative_filepath = File.join('spec', 'fixtures', 'xml', 'diagnostic_v2_summative.xml')
    create_activity_with_content(
      summative_filepath,
      program,
      {
        grading_method: 'auto',
        max_attempts: 1
      }.merge(opts)
    ).tap do |summative|
      summative.title = 'Prueba de práctica'
      summative.save!
    end
  end

  def create_formative_activity(program, opts = {})
    formative_filepath = File.join('spec', 'fixtures', 'xml', 'diagnostic_v2_formative.xml')
    create_activity_with_content(
      formative_filepath,
      program,
      {
        grading_method: 'auto',
        max_attempts: 1
      }.merge(opts)
    ).tap do |formative|
      # cms_activity_id from formative_activity in summative activity fixture.
      formative.cms_activity_id = 67_816
      formative.save!
    end
  end

  def create_activities_with_the_same_toc_location(program, amount = 1, opts = {}, &block)
    location_attrs = opts.slice(:lesson, :strand_id)
    non_location_attrs = opts.except(:strand_id)
    location_attributes = activity_location_attributes(program, location_attrs)
    Array.new(amount) do
      if block_given?
        block.call(location_attributes.merge(non_location_attrs))
      else
        create(:activity, location_attributes.merge(non_location_attrs))
      end
    end
  end

  def create_activity_with_unit_lesson_concept_strand_and_substrand(program, opts = {})
    unit = create(:unit, program: program, rank: 1)
    lesson = unit.lessons.first
    lesson ||= create(:lesson, unit: unit)

    strand = create(:toc_entry)
    substrand = create(:toc_entry)
    strand.children = [substrand]

    lesson.toc_entries = [strand]
    lesson.save!
    concept = create(
      :concept,
      id: strand.location,
      lesson: lesson,
      program: program
    )

    base_opts = {
      concept: concept,
      lesson: lesson,
      max_attempts: 3,
      toc_location: substrand.location
    }
    activity = build(:activity, base_opts.merge(opts))
    activity.extend(ActivityXmlContentHelper)
    activity.save!
    activity
  end

  def create_assessment_with_unit_lesson_concept(program, opts = {}, keep_toc_entries = false)
    content_filepath = File.join('spec', 'fixtures', 'xml', 'exam.xml')
    allow(Activity).to receive(:filepath_from_revision_id).and_return(content_filepath)
    create(:activity, assessment_location_attributes(program, opts, keep_toc_entries))
  end

  def create_mixed_grading_type_assessment_with_unit_lesson_concept(program, opts = {})
    content_filepath = File.join('spec', 'fixtures', 'xml', 'mixed_grading_type.xml')
    allow(Activity).to receive(:filepath_from_revision_id).and_return(content_filepath)
    create(:activity, assessment_location_attributes(program, opts))
  end

  def create_instructor_activity_with_unit_lesson_concept_strand_and_substrand(program, opts = {})
    unit = create(:unit, program: program, rank: 1)
    lesson = unit.lessons.first
    lesson ||= create(:lesson, unit: unit)

    strand = create(:toc_entry)
    substrand = create(:toc_entry)
    strand.children = [substrand]

    lesson.toc_entries = [strand]
    lesson.save!
    concept = create(
      :concept,
      id: strand.location,
      lesson: lesson,
      program: program
    )

    base_opts = {
      concept: concept,
      lesson: lesson,
      max_attempts: 3,
      toc_location: substrand.location
    }.merge(opts)
    allow(Maestro::LicenseGroup).to receive(:all).and_return([])

    stub_request(
      :any,
      %r{https\://s3\.amazonaws\.com\/vhlcentral\.activities/.*\.xml}
    ).to_return(status: 200, body: '', headers: {})

    create(:instructor_created_activity, base_opts)
  end

  def create_fill_in_the_blanks_activity_with_model(program)
    fill_in_the_blanks_content_path = File.join(
      'spec',
      'fixtures',
      'xml',
      'fill_in_the_blanks_with_model.xml'
    )
    create_activity_with_content(fill_in_the_blanks_content_path, program)
  end

  def create_grouped_vocab_activity(program, opts = {})
    activity_content_path = File.join(
      'spec',
      'fixtures',
      'xml',
      'grouped_vocab_activity.xml'
    )
    create_activity_with_content(activity_content_path, program, opts)
  end

  def create_reference_activity_with_reference_groups(program, opts = {})
    activity_content_path = File.join(
      'spec',
      'fixtures',
      'xml',
      'reference_activity_with_reference_groups.xml'
    )
    create_activity_with_content(activity_content_path, program, opts)
  end

  def create_vocab_group_activity_model(program)
    fill_in_the_blanks_content_path = File.join('spec', 'fixtures', 'xml', 'vocab_list.xml')
    cms_revision_id = generate(:cms_revision_id)
    allow(Activity).to receive(:filepath_from_revision_id).with(
      cms_revision_id,
      false
    ).and_return(fill_in_the_blanks_content_path)
    opts = { cms_revision_id: cms_revision_id }
    activity = create_activity_with_unit_lesson_and_concept(program, opts)
    activity
  end

  def create_reference_activity_with_glosses(program)
    content_path = File.join('spec', 'fixtures', 'xml', 'reference_activity_with_glosses.xml')
    activity = create_activity_with_unit_lesson_and_concept(program)
    allow(Activity).to receive(:filepath_from_revision_id).and_return(content_path)
    activity
  end

  def create_flashcards_activity(program, opts = {})
    content_path = File.join('spec', 'fixtures', 'xml', 'flashcards.xml')
    cms_revision_id = generate(:cms_revision_id)
    opts = { cms_revision_id: cms_revision_id }.merge(opts)
    allow(Activity).to receive(:filepath_from_revision_id).with(
      cms_revision_id,
      false
    ).and_return(content_path)
    activity = create_activity_with_unit_lesson_and_concept(program, opts)
    activity
  end

  def create_click_and_reveal_activity(program)
    content_path = File.join('spec', 'fixtures', 'xml', 'click_and_reveal.xml')
    create_activity_with_content(content_path, program)
  end

  def create_cumulative_matching_activity(program)
    cumulative_matching_content_path = File.join('spec', 'fixtures', 'cumulative_matching.xml')
    create_activity_with_content(cumulative_matching_content_path, program)
  end

  def create_true_false_enhanced_activity(program)
    create_activity_with_content(
      File.join('spec', 'fixtures', 'xml', 'true_false_enhanced.xml'),
      program,
      grading_method: 'instructor',
      points_possible: 10
    )
  end

  def create_short_clips_activity(program)
    short_clips_activity_content_path = File.join('spec', 'fixtures', 'xml', 'short_clips.xml')
    create_activity_with_content(short_clips_activity_content_path, program)
  end

  def create_short_clips_activity_with_phrase_chart(program)
    short_clips_activity_content_path = File.join('spec', 'fixtures', 'xml', 'short_clips_with_phrase_chart.xml')
    create_activity_with_content(short_clips_activity_content_path, program)
  end

  def create_reference_activity_with_phrase_chart(program)
    reference_activity_content_path = File.join('spec', 'fixtures', 'xml', 'reference_activity_with_phrase_chart.xml')
    create_activity_with_content(reference_activity_content_path, program)
  end

  def create_reference_activity_with_citation_reference(program)
    reference_activity_content_path = File.join('spec', 'fixtures', 'xml', 'reference_activity_with_citation_reference.xml')
    create_activity_with_content(reference_activity_content_path, program)
  end

  def create_activity(program, fixture_filename)
    activity_content_path = File.join('spec', 'fixtures', fixture_filename)
    create_activity_with_content(activity_content_path, program)
  end

  def create_column_matching_activity(program)
    create_activity_with_content(
      File.join('spec', 'fixtures', 'xml', 'column_matching.xml'),
      program,
      grading_method: 'auto',
      max_attempts: 1
    )
  end

  def create_pronunciation_explore_activity(program)
    content_path = File.join('spec', 'fixtures', 'xml', 'pronunciation_explore_activity.xml')
    create_activity_with_content(content_path, program)
  end

  def create_table_inline_open_ended_activity(program)
    create_activity_with_content(
      File.join('spec', 'fixtures', 'xml', 'table_inline_oe.xml'),
      program,
      grading_method: 'instructor',
      max_attempts: 3, # for test purposes only; activity has one attempt irl.
      points_possible: 4
    )
  end

  def create_open_ended_activity(program)
    create_activity_with_content(
      File.join('spec', 'fixtures', 'xml', 'open_ended.xml'),
      program,
      grading_method: 'instructor',
      points_possible: 40
    )
  end

  def create_inline_open_ended_activity(program)
    create_activity_with_content(
      File.join('spec', 'fixtures', 'xml', 'inline_open_ended.xml'),
      program,
      grading_method: 'instructor',
      points_possible: 40
    )
  end

  def create_open_ended_assessment(program)
    content_filepath = File.join('spec', 'fixtures', 'xml', 'open_ended.xml')
    allow(Activity).to receive(:filepath_from_revision_id).and_return(content_filepath)
    create(
      :activity,
      assessment_location_attributes(program).merge(grading_method: 'instructor')
    )
  end

  def create_mixed_grading_type_assessment(program)
    content_filepath = File.join('spec', 'fixtures', 'xml', 'mixed_grading_type.xml')
    allow(Activity).to receive(:filepath_from_revision_id).and_return(content_filepath)
    create(
      :activity,
      assessment_location_attributes(program).merge(grading_method: 'mixed')
    )
  end

  def create_multiple_choice_activity(program)
    create_activity_with_content(
      File.join('spec', 'fixtures', 'xml', 'multiple_choice.xml'),
      program,
      grading_method: 'auto'
    )
  end

  def create_multiple_answer_activity(program)
    create_activity_with_content(
      File.join('spec', 'fixtures', 'xml', 'multiple_answer.xml'),
      program,
      grading_method: 'auto'
    )
  end

  def create_fill_in_the_blanks_activity_with_sidenotes(program)
    fill_in_the_blanks_content_path = File.join(
      'spec',
      'fixtures',
      'xml',
      'fill_in_the_blanks_with_sidenotes.xml'
    )
    create_activity_with_content(fill_in_the_blanks_content_path, program)
  end

  def create_solo_video_recording_activity(program)
    solo_video_recording_content_path = File.join(
      'spec',
      'fixtures',
      'xml',
      'solo_video_recording.xml'
    )
    create_activity_with_content(solo_video_recording_content_path, program)
  end

  def create_solo_video_recording_activity_with_rubric(program)
    solo_video_recording_content_path = File.join(
      'spec',
      'fixtures',
      'xml',
      'solo_video_recording_with_rubric.xml'
    )
    create_activity_with_content(solo_video_recording_content_path, program)
  end

  def create_composition_activity_with_rubric(program)
    composition_content_path = File.join(
      'spec',
      'fixtures',
      'xml',
      'composition_with_rubric.xml'
    )
    create_activity_with_content(composition_content_path, program)
  end

  def create_multi_type_with_solo_video_recording_activity(program)
    multitype_with_solo_video_recording_content_path = File.join(
      'spec',
      'fixtures',
      'xml',
      'multi_type_activity_with_solo_video.xml'
    )
    create_activity_with_content(multitype_with_solo_video_recording_content_path, program)
  end

  def create_activity_with_content(content_filepath, program, opts = {})
    # Need to set a default stub for :filepath_from_revision_id to avoid errors like
    # "Unsupported source provided: was NilClass but should be File, XML string
    # or Nokogiri::XML::Node".
    # But creating the default stub wipes out all previously created revision-id-specific
    # stubs. Querying Rspec::Mocks for Activity class shows whether method is already stubbed.
    opts = {
      max_attempts: 3,
      page: '3-6'
    }.merge(opts)
    stubbed_methods = RSpec::Mocks.space.proxy_for(Activity).instance_variable_get(:@method_doubles)
    unless stubbed_methods.key?(:filepath_from_revision_id)
      allow(Activity).to receive(:filepath_from_revision_id).and_return('')
    end
    activity = create_activity_with_unit_lesson_and_concept(program, opts)
    allow(Activity).to receive(:filepath_from_revision_id).with(
      activity.revision_id,
      false,
      false
    ).and_return(content_filepath)
    # reload activity to have a content object
    activity = Activity.find(activity.id)
    # save the activity to set the denormalized values from the content object
    activity.save!
    # Override some attributes if present and non nil.
    overridable_attrs = %i[max_attempts].freeze
    override_attrs = opts.slice(*overridable_attrs).reject { |_k, v| v.nil? }
    if false && Rails.version >= 4
      override_attrs.count.positive? activity.update_columns(override_attrs)
    else
      override_attrs.each do |attr, value|
        activity.update_column(attr, value)
      end
    end
    activity
  end

  def create_smart_book_activity_from_fixture(program, activity_xml_fixture:, project_json_fixture:, **opts)
    smartbook_xml_file = File.join('spec', 'fixtures', 'xml', activity_xml_fixture)
    project_json_file = File.join('spec', 'fixtures', 'json', project_json_fixture)
    learning_package = Nokogiri::XML.parse(
      File.read(smartbook_xml_file)
    ).xpath('//learning_package')[0][:path]
    stub_request(
      :get,
      URI::HTTPS.build(
        host: Rails.application.config.santillana_book_host,
        path: File.join('', learning_package, 'project.json')
      )
    ).to_return(status: 200, body: File.read(project_json_file))
    create_activity_with_content(smartbook_xml_file, program, opts)
  end

  def create_smart_book_activity(program, opts = {})
    create_smart_book_activity_from_fixture(
      program,
      **{
        activity_xml_fixture: 'smart_book.xml',
        project_json_fixture: 'smart_book_project.json'
      }.merge(opts)
    )
  end

  def create_hybrid_reading_activity(program)
    create_activity_with_content(
      File.join('spec', 'fixtures', 'xml', 'hybrid_reading.xml'),
      program,
      grading_method: 'auto'
    )
  end

  def create_study_plan_practice_test_activity(program)
    create_activity_with_content(
      File.join('spec', 'fixtures', 'xml', 'study_plan_practice_test.xml'),
      program,
      grading_method: 'auto'
    )
  end

  def cancel_activity
    footer = find('#activityFooter .activity_actions')
    within footer do
      click_link('cancel')
    end
  end

  def save_activity
    form = find('.edit_instructor_created_activity')
    within form do
      find('[type="submit"]').click
    end
  end

  def submit_activity
    form = find('#activity_form')
    within form do
      click_button('Submit')
    end
  end

  def build_activity(fixture_filename)
    fixture_file = File.join(File.dirname(__FILE__), fixture_filename)
    parser = MaestroActivityEngine::ActivityParser.create_parser(File.new(fixture_file), linked_media_class)
    content = parser.parse
    activity = build(:activity)
    allow(activity).to receive(:content_object).and_return(content)
    allow(content).to receive(:content_summary).and_return(MaestroActivityEngine::ActivityContent::ContentSummary.new(content))
    activity
  end
end
