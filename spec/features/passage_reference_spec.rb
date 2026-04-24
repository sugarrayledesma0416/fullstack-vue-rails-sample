feature 'Passage Reference', chrome: true, js: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program) }
  let(:assessment_strand) { create(:toc_entry) }
  let(:course) do
    create(:course,
           owner: instructor,
           program:,
           allows_help_requests: true,
           allows_review_requests: true)
  end
  let(:section) { create(:section, course:, instructor:) }
  let(:unit) { create(:unit, program:) }
  let(:lesson) { create(:lesson, toc_entries: [assessment_strand], unit:) }
  let(:activity) do
    create(:json_activity_with_passage, title: 'Mid-Unit Assessment', lesson:)
  end
  let(:image_media_item) do
    create(:media_item_image, id: 1023, filename: 'unit_1.png', height: 100,
                              long_description: 'This is sample description')
  end

  let(:category) { create(:category, course:, penalty_percent: 0) }

  def link_image(media_item, fixture_file)
    source_path = File.join('spec', 'fixtures', 'media_items', fixture_file)
    dest_path = media_item.full_filename
    FileUtils.makedirs(File.dirname(dest_path))
    FileUtils.cp(source_path, dest_path)
    @recycle_bin << dest_path
  end

  before do
    link_image(image_media_item, 'unit_1.png')
  end

  def validate_passage_reference
    step 'I can see passage reference text' do
      expect(page).to have_selector(
        '.test-reference-passage__body',
        text: 'This is test passage reference'
      )
    end

    step 'I can see image in the passage' do
      expect(page).to have_selector(
        ".test-reference-passage img[src='#{image_media_item.public_filename}']"
      )
    end

    step 'I can see image description in the passage' do
      expect(page).to have_selector(
        '.test-reference-passage .test-media-item-desc',
        text: image_media_item.long_description
      )
    end

    step 'I can add help request to passage reference' do
      expect(page).to have_selector(
        '.test-reference-passage[data-helpable-type="reference_passage"]',
        text: 'This is test passage reference'
      )
    end
  end

  scenario 'As a student, I can view the assessment with passage reference ' \
           'in preview mode' do
    create(:enrollment, user: student, section: section)
    create(
      :assignment,
      assignable: activity,
      category:,
      due_date: Date.tomorrow,
      section:
    )

    give_user_access_to_program(student, program)
    log_in_as(student)
    visit section_activity_path(section_id: section.id, id: activity.id)
    validate_passage_reference
  end

  scenario 'As a student, I can view the passage reference ' \
           'in practice mode' do
    create(:enrollment, user: student, section:)
    create(
      :assignment,
      assignable: activity,
      category:,
      due_date: Date.tomorrow,
      section:
    )
    create(:attempt_completed, activity:, section:, user: student)

    give_user_access_to_program(student, program)
    log_in_as(student)
    visit practice_section_activity_path(section_id: section.id, id: activity.id)

    validate_passage_reference
  end
end
