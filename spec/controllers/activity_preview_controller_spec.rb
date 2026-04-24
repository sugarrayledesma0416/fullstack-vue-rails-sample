describe ActivityPreviewController do
  let(:instructor) { create(:instructor) }
  let(:xml) do
    <<-XML
      <activity activity_type="blank" title="Preview activity" language="es">
        <dl/>
        <items/>
      </activity>
    XML
  end
  let(:cache_mgr) { double(CacheManager) }
  let(:program_with_toc) { create(:program_with_toc_entries) }
  let(:program_with_no_toc) { create(:program) }

  describe '#process_preview' do
    let(:default_params) do
      {
        activity: {
          activity_type: 'blank',
          cms_revision_id: 1000,
          content: xml
        },
        program_id: program_with_no_toc.id
      }
    end
    let(:expected_cache_key) { Digest::MD5.hexdigest(xml) }

    def do_request(opts = {})
      post :process_preview, params: default_params.deep_merge(opts)
    end

    before do
      allow(CacheManager).to receive(:new) { cache_mgr }
      allow(cache_mgr).to receive(:cache_put)
    end

    it 'saves content to a cache' do
      expect(cache_mgr).to receive(:cache_put)
        .with(expected_cache_key, xml, 1.hour.to_i)
      do_request
    end

    it 'redirects to the preview_activity action' do
      expected_params = {
        activity: default_params[:activity].except(:content),
        program_id: program_with_toc.id
      }
      expected_params.deep_merge!(activity: { content_key: expected_cache_key })

      do_request(program_id: program_with_toc.id)
      expected_redirect = preview_activity_path(expected_params)
      expect(response).to redirect_to(expected_redirect)
    end

    context 'when requested progam is invalid' do
      let!(:fallback_program) { build_stubbed(:program, id: 79) }

      it 'does not error when program is missing' do
        expect { do_request(program_id: program_with_no_toc.id + 1) }
          .to_not raise_error
      end

      it 'does not error when program has no lessons' do
        expect { do_request(program_id: program_with_no_toc.id) }
          .to_not raise_error
      end

      it 'defaults to program_id 79' do
        expected_params = {
          activity: default_params[:activity].except(:content),
          program_id: fallback_program.id
        }
        expected_params.deep_merge!(activity: { content_key: expected_cache_key })

        do_request
        expected_redirect = preview_activity_path(expected_params)
        expect(response).to redirect_to(expected_redirect)
      end
    end
  end

  describe '#show' do
    let(:program) { create(:program_with_toc_entries) }
    let(:bad_xml) { '<activity activity_type="blank" title="none"><dl/><items/></activity>' }
    let(:default_params) do
      {
        activity: {
          activity_type: 'blank',
          cms_revision_id: 1000,
          content_key: 'test_content_key'
        },
        program_id: program.id
      }
    end

    def do_request(opts = {})
      get :show, params: default_params.deep_merge(opts)
    end

    before do
      fake_login(instructor)
      allow(CacheManager).to receive(:new) { cache_mgr }
      allow(cache_mgr).to receive(:cache_get)
        .with(default_params[:activity][:content_key])
        .and_return xml
    end

    it_behaves_like 'an action that requires a logged in user'

    it 'creates a presenter' do
      do_request
      expect(assigns[:activity_presenter]).to be_a StudentActivityPresenter
    end

    it 'creates a read-only preview activity object' do
      do_request
      expect(assigns[:activity]).to be_a PreviewActivity
      expect do
        assigns[:activity].save(validate: false)
      end.to raise_error ActiveRecord::ReadOnlyRecord
    end

    it 'creates a preview activity object with attributes in current_program' do
      do_request
      created_activity = assigns[:activity]
      expected_lesson_id = program.lessons.first.id
      expected_strand_loc = program.lessons.first.strands.first.location.to_i
      expected_concept_id = expected_strand_loc

      expect(created_activity.lesson_id).to eq expected_lesson_id
      expect(created_activity.toc_location).to eq expected_strand_loc
      expect(created_activity.concept_id).to eq expected_concept_id
    end

    it 'assigns the title to the activity object' do
      do_request
      expect(assigns[:activity].title).to eq 'Preview activity'
    end

    it 'creates a preview attempt object' do
      do_request
      expect(assigns[:attempt]).to be_a PreviewAttempt
    end

    it 'set the section to zero' do
      do_request
      expect(assigns[:current_section]).to eq Section.section_zero
    end

    it 'assigns video_settings' do
      do_request
      expect(assigns[:video_settings]).to be_a MaestroActivityEngine::VideoSettings
    end

    it 'sets a flash message' do
      do_request
      expect(flash[:notice]).to eq 'CMS Preview'
    end

    it 'will raise an error if the activity does not parse' do
      allow(cache_mgr).to receive(:cache_get)
        .with('other_key')
        .and_return bad_xml
      expect { do_request(activity: { content_key: 'other_key' }) }
        .to raise_error StandardError, 'attribute "language" is required at line: 1'
    end
  end

  describe '#preview_answer_key' do
    let(:program) { create(:program_with_toc_entries) }
    let(:bad_xml) { '<activity activity_type="blank" title="none"><dl/><items/></activity>' }
    let(:default_params) do
      {
        activity: {
          activity_type: 'blank',
          cms_revision_id: 1000,
          content_key: 'test_content_key'
        },
        program_id: program.id
      }
    end

    def do_request(opts = {})
      get :preview_answer_key, params: default_params.deep_merge(opts)
    end

    before do
      fake_login(instructor)
      allow(Program).to receive(:find_by_id) { program }
      allow(CacheManager).to receive(:new) { cache_mgr }
      allow(cache_mgr).to receive(:cache_get)
        .with(default_params[:activity][:content_key])
        .and_return xml
    end

    it_behaves_like 'an action that requires a logged in user'

    it 'creates a presenter' do
      do_request
      expect(assigns[:activity_presenter]).to be_a StudentActivityPresenter
    end

    it 'creates a read-only preview activity object' do
      do_request
      expect(assigns[:activity]).to be_a PreviewActivity
      expect do
        assigns[:activity].save(validate: false)
      end.to raise_error ActiveRecord::ReadOnlyRecord
    end

    it 'creates a preview activity object with attributes in current_program' do
      do_request
      created_activity = assigns[:activity]
      expected_lesson_id = program.lessons.first.id
      expected_strand_loc = program.lessons.first.strands.first.location.to_i
      expected_concept_id = expected_strand_loc

      expect(created_activity.lesson_id).to eq expected_lesson_id
      expect(created_activity.toc_location).to eq expected_strand_loc
      expect(created_activity.concept_id).to eq expected_concept_id
    end

    it 'assigns the title to the activity object' do
      do_request
      expect(assigns[:activity].title).to eq 'Preview activity'
    end

    it 'creates a preview attempt object' do
      do_request
      expect(assigns[:attempt]).to be_a PreviewAttempt
    end

    it 'sets the section to zero' do
      do_request
      expect(assigns[:current_section]).to eq Section.section_zero
    end

    it 'sets a flash message' do
      do_request
      expect(flash[:notice]).to eq 'CMS Preview Answer Key'
    end

    it 'will raise an error if the activity does not parse' do
      allow(cache_mgr).to receive(:cache_get)
        .with('other_key')
        .and_return bad_xml
      expect { do_request(activity: { content_key: 'other_key' }) }
        .to raise_error StandardError, 'attribute "language" is required at line: 1'
    end
  end
end
