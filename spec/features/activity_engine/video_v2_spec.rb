def create_video_v2_activity(program)
  create_activity_with_content(
    File.join('spec', 'fixtures', 'xml', 'video_v2.xml'),
    program,
    grading_method: 'auto'
  )
end

feature 'Video v2 activity', js: true, chrome: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include Capybara::Angular::DSL
  include ActivityTest::Helpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_lessons) }
  let(:course) { create(:course, owner: instructor, program: program) }
  let(:section) { create(:section, course: course, instructor: instructor) }

  # Both media items needs the ID attribute because that's the value specified in the video_v2 fixture.
  let!(:video_media_items) do
    [
      create(:media_item_video, id: 1, filename: 'video_high_res.mp4', width: 700, height: 525),
      create(:media_item_video, id: 2, filename: 'video_low_res.mp4', width: 400, height: 300)
    ]
  end

  let(:activity) { create_video_v2_activity(program) }
  let(:activity_data) { ActivityTest::ActivityData::VideoV2.new(activity, video_media_items) }
  let(:activity_url) { section_activity_path(0, activity) }
  let(:video_selector) { '#video-top-pane video' }

  before do
    give_user_access_to_program(student, program)
    log_in_as(student)
  end

  scenario 'Student does a video v2 activity' do
    visit activity_url

    for_unsubmittable_page(activity_data) do
      expect_activity_shell_structure_to_be_complete
      expect(@page_object).to have_been_viewed

      # Click the play button
      find('button.vjs-big-play-button').click
      # Check video src
      expect(find(video_selector)['src']).to end_with(activity_data.video_media_item_high_res.filename)
    end
  end
end
