describe UnlistedActivityPublishProcessor do
  # This relies on base class' - ActivityPublishProcessor - specs

  let(:program) do
    create(
      :program,
      title: 'Book 1',
      vhlcentral_subdomain: 'Book 1'.parameterize.to_s
    )
  end
  let(:unit) { create(:unit, program: program, rank: 1) }
  let(:lesson) { create(:lesson_with_strands_substrands, unit: unit, rank: 0) }
  let(:concept) do
    create(
      :concept,
      id: lesson.strands.first.location,
      lesson: lesson,
      program: program
    )
  end
  let(:new_revision_id) { 2 }
  let(:associated_params) do
    {
      'content' => nil,
      'lesson_rank' => lesson.rank,
      'program_id' => program.id,
      'unit_rank' => unit.rank
    }
  end

  let(:unlisted_activity_params) do
    {
      'assignment_group' => 'Practice',
      'cdn' => true,
      'cms_activity_id' => '1',
      'cms_revision_id' => new_revision_id,
      'component_name' => 'Unlisted',
      'concept_id' => concept.id,
      'concept_rank' => concept.rank,
      'icon' => 'some_icon_name',
      'lesson_id' => lesson.id,
      'license_group_id' => 4,
      'page' => '3',
      'points_possible' => 10,
      'title' => 'Activity 1',
      'toc_location' => nil
    }
  end

  let(:params) { unlisted_activity_params.merge(associated_params) }
  let!(:processor) { described_class.new(params) }
  let(:cms_updater_klass) { ActivityPublishProcessor::CmsRevisionUpdater }

  it 'inherits from ActivityPublishProcessor' do
    expect(processor).to be_a ActivityPublishProcessor
  end

  describe '#process_request' do
    let(:updater) do
      instance_double(
        cms_updater_klass,
        current_version_has_already_been_published?: true,
        updated_activities: []
      )
    end

    before do
      allow(cms_updater_klass).to receive(:new).and_return(updater)
      allow(updater).to receive(:update_revision_ids_and_cdn).and_return(updater)
      stub_request(
        :any,
        %r{https\://s3\.amazonaws\.com\/vhlcentral\.activities/.*\.xml}
      ).to_return(status: 200, body: '', headers: {})
    end

    it 'instantiates an ActivityPublishProcessor::CmsRevisionUpdater object ' \
       'and calls to updates_revision_ids method' do
      processor.process_request

      expect(cms_updater_klass).to have_received(:new)
      expect(updater).to have_received(:update_revision_ids_and_cdn)
    end

    it 'sets lesson id value in the processor request params when a lesson is found' do
      processor.process_request
      expect(processor.request['lesson_id']).to eq lesson.id
    end

    it 'sets toc location value in the processor request params to nil' do
      processor.process_request
      expect(processor.request['toc_location']).to be_nil
    end

    it 'does an activity lookup by cms_activity_id, toc_location set ' \
       'to nil, component_name and lesson_id' do
      expected_args = {
        cms_activity_id: params['cms_activity_id'],
        lesson_id: params['lesson_id']
      }
      expect(Activity).to receive(:find_by).with(expected_args).and_return([])
      processor.process_request
    end

    it 'creates a new activity if none is found' do
      allow(Activity).to receive(:where).and_return([])
      expect { processor.process_request }.to change(Activity, :count).by(1)
    end

    it 'sets the cdn value on the published activity' do
      processor.process_request

      expect(
        Activity.where(
          cms_activity_id: unlisted_activity_params['cms_activity_id']
        ).first.cdn
      ).to eq unlisted_activity_params['cdn']
    end

    it 'updates an existing activity' do
      existing_activity = create(
        :activity,
        unlisted_activity_params.merge(cms_revision_id: new_revision_id - 1)
      )
      processor.process_request
      expect(Activity.find(existing_activity.id).cms_revision_id).to eq new_revision_id
    end

    it 'creates a new activity if there is an existing activity in a different lesson' do
      other_lesson = create(:lesson)
      create(
        :activity,
        lesson_id: other_lesson.id,
        cms_activity_id: unlisted_activity_params['cms_activity_id']
      )
      expect { processor.process_request }.to change(Activity, :count).by(1)
    end
  end
end
