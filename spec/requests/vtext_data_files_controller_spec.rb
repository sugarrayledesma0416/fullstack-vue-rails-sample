require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe VtextDataFilesController do
  let(:user) { create(:instructor) }
  let!(:activity) do
    create(:activity,
           cms_activity_id: 1,
           toc_location: lesson.toc_entries.first.location,
           has_vhl_image: true,
           assignment_group: 'Practice',
           icon: 'audio, textbook, video',
           lesson: lesson)
  end
  let(:data_generator) { VtextDataGenerator.new(program.id) }
  let(:program) { create(:program) }
  let!(:unit) { create(:unit, program: program) }
  let!(:role) { create(:role) }
  let!(:lesson) { create(:lesson_with_strands_and_activities, unit: unit) }
  let(:concept) do
    create(:concept,
           activities: [activity],
           name: lesson.toc_entries.detect do |toc_entry|
             toc_entry.location == activity.toc_location.to_s
           end.title)
  end

  LICENSE_GROUP = {
    1 => '01-Supersite',
    2 => '02-Supersite_Plus',
    3 => 'WebSAM',
    4 => '00-Media_Only',
    21 => 'VOL',
    23 => 'Premium'
  }.freeze

  describe '#create' do
    def do_request(params = {})
      post vtext_data_files_path, params: params
    end

    include_examples 'require logged in user'

    it 'when user has vtext_creator as role, he can generate a CSV file' do
      user.roles << role
      log_in_user(user)
      bom = "\uFEFF"
      expected_headers = ["#{bom}unit_lesson",
                          'strand_name',
                          'content_category',
                          'activity_type',
                          'mouse_icon',
                          'lesson_rank',
                          'strand_rank',
                          'activity_rank',
                          'rank',
                          'activity_title',
                          'activity_source_code',
                          'cms_activity_id',
                          'license_group',
                          'm3_link',
                          'audio',
                          'image',
                          'video',
                          'assignment_group']

      expected_data = [lesson.name,
                       concept.name,
                       activity.component_name,
                       activity.activity_type,
                       (activity.icon.include? 'textbook').to_s,
                       lesson.rank.to_s,
                       activity.toc_location_rank.to_s,
                       activity.concept_rank.to_s,
                       activity.concept_rank.to_s,
                       activity.title,
                       activity.id.to_s,
                       activity.cms_activity_id.to_s,
                       LICENSE_GROUP[activity.license_group_id],
                       "m3a.vhlcentral.com/sections/0/activities/#{activity.id}",
                       (activity.icon.include? 'audio').to_s,
                       activity.has_vhl_image.to_s,
                       (activity.icon.include? 'video').to_s,
                       activity.assignment_group]

      do_request(program_id: program.id)
      csv_data = CSV.parse(response.body)
      expected = [expected_headers] + [expected_data]
      expect(csv_data).to eq(expected)
    end

    it 'when user does not have vtext_creator as role, he can not generate a CSV file' do
      log_in_user(user)
      do_request(program_id: program.id)
      expect(response).to redirect_to '/403'
    end
  end

  describe '#index' do
    def do_request
      get vtext_data_files_path
    end

    include_examples 'require logged in user'

    it 'shows the index page if the user has a session and the vtext_creator role' do
      user.roles << role
      log_in_user(user)
      do_request
      result = Capybara.string(response.body)
      expect(response.status).to eq 200
      expect(result).to have_content('Activity Links Export')
    end

    it 'redirects to an error page when the user does not have vtext_creator as a role' do
      log_in_user(user)
      do_request
      expect(response).to redirect_to '/403'
    end
  end
end
