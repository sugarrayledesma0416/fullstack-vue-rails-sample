feature 'Table Reference', chrome: true, js: true do
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
    create(:json_activity_with_table, title: 'Mid-Unit Assessment', lesson:)
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

  def validate_table_reference
    step 'I can see table reference text' do
      expect(page).to have_selector(
        'table.c-table > caption',
        text: 'Default Table'
      )
    end

    step 'I can see table headers' do
      expect(page).to have_selector(
        'tr.c-header-row > th.c-header-cell',
        text: 'COLUMN_1'
      )
      expect(page).to have_selector(
        'tr.c-header-row > th.c-header-cell',
        text: 'COLUMN_2'
      )
    end
  end

  scenario 'As a student, I can view the assessment with table reference ' \
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
    validate_table_reference
  end
end
