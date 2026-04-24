require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe ActivityPreviewController do
  let(:content_key) { 'a52ddbebbe653e8193f884bf7c3202c9' }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_toc_entries) }
  let(:lesson) { program.units.first.lessons.first }
  let(:strand) { lesson.strands.first }
  let(:content) do
    File.read(File.join('spec', 'fixtures', 'xml', 'drop_down_same.xml'))
  end

  describe 'GET /show' do
    let(:url_params) do
      {
        activity: {
          activity_type: 'drop_down_same',
          cms_revision_id: FactoryBot.generate(:cms_revision_id),
          content_key: 'a52ddbebbe653e8193f884bf7c3202c9'
        },
        program_id: program.id
      }
    end

    before do
      create(:concept, lesson: lesson, id: strand.location)
      content_cache = CacheManager.new('cms_preview_content')
      content_cache.cache_put(content_key, content, 10.seconds.to_i)
    end

    it 'does not throw "unable to convert unpermitted parameters to hash"' do
      log_in_user_with_access_to_programs(student, [program])

      expect do
        get preview_activity_path(url_params)
      end.not_to raise_error
    end
  end
end
