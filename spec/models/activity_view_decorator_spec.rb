describe ActivityViewDecorator, core: true do
  let(:activity) { build(:activity).extend(described_class) }
  let(:program) { build(:program) }
  let(:mock_vocab_group) do
    instance_spy(MaestroActivityEngine::ActivityContent::VocabList::Group, id: 1)
  end
  let(:mock_content_object) { double('ContentObject', groups: [mock_vocab_group]) }
  let(:media_item) do
    instance_double(MediaItem, base_dir: 'base_directory_path',
                               unzipped_directory: 'unzipped_directory_path',
                               csv_content: 'csv_content_data')
  end

  before do
    allow(activity).to receive(:content_object).and_return(mock_content_object)
    allow(mock_content_object).to receive(:ensure_public_media_files)
    allow(mock_content_object).to receive(:populate_dirs_from_media)
    allow(mock_content_object).to receive(:activity_order_seed=)
  end

  describe '#populate_vocab_groups' do
    before do
      allow(MediaItem).to receive(:find).with(mock_vocab_group.id)
                                        .and_return(media_item)
    end

    it 'setups the vocab_group media if the content object has groups' do
      activity.populate_vocab_groups
      expect(mock_vocab_group).to have_received(:base_dir=).with(media_item.base_dir)
      expect(mock_vocab_group).to have_received(:public_dir=).with(media_item.unzipped_directory)
      expect(mock_vocab_group).to have_received(:content_csv=).with(media_item.csv_content)
      expect(mock_vocab_group).to have_received(:populate_content_from_csv)
    end

    it 'does nothing if the the vocab_group has no id' do
      allow(mock_vocab_group).to receive(:id).and_return(nil)
      activity.populate_vocab_groups
      expect(mock_vocab_group).not_to have_received(:base_dir=)
      expect(mock_vocab_group).not_to have_received(:public_dir=)
      expect(mock_vocab_group).not_to have_received(:content_csv=)
      expect(mock_vocab_group).not_to have_received(:populate_content_from_csv)
    end
  end

  describe '#populate_activity_media' do
    before do
      allow(activity).to receive(:populate_vocab_groups)
    end

    it 'populates the vocab groups if the activity is a vocab_list' do
      allow(mock_content_object).to receive(:activity_type).and_return('vocab_list')
      activity.populate_activity_media
      expect(activity).to have_received(:populate_vocab_groups)
      expect(mock_content_object).not_to have_received(:populate_dirs_from_media)
      expect(mock_content_object).not_to have_received(:ensure_public_media_files)
    end

    it 'populates the media directories if the activity is a vocab tutorial' do
      allow(mock_content_object).to receive(:activity_type).and_return('tutorial_vocab')
      activity.populate_activity_media
      expect(mock_content_object).to have_received(:populate_dirs_from_media)
      expect(mock_content_object).not_to have_received(:ensure_public_media_files)
      expect(activity).not_to have_received(:populate_vocab_groups)
    end

    it 'populates the media directories if the activity is an html5 vocab tutorial' do
      allow(mock_content_object).to receive(:activity_type).and_return('tutorial_vocab_html5')
      activity.populate_activity_media
      expect(mock_content_object).to have_received(:populate_dirs_from_media)
      expect(activity).not_to have_received(:populate_vocab_groups)
      expect(mock_content_object).not_to have_received(:ensure_public_media_files)
    end

    it 'populates the media directories if the activity is a game' do
      allow(mock_content_object).to receive(:activity_type).and_return('game')
      activity.populate_activity_media
      expect(mock_content_object).to have_received(:ensure_public_media_files)
      expect(mock_content_object).not_to have_received(:populate_dirs_from_media)
      expect(activity).not_to have_received(:populate_vocab_groups)
    end
  end

  describe '#randomize' do
    it 'assigns a seed number to the activity content object' do
      random_number = rand(100)
      activity.randomize(random_number)
      expect(mock_content_object).to have_received(:activity_order_seed=).with(random_number)
    end
  end

  describe '#initialize_vtext_linker' do
    it 'assigns a vtext_linker' do
      expect(activity.vtext_linker).to be_nil
      vtext_linker = instance_double(VtextLinker)
      presenter = instance_double(InstructorActivityPresenter)
      allow(VtextLinker).to receive(:new).with(program, presenter, activity, session: {})
                            .and_return(vtext_linker)
      activity.initialize_vtext_linker(program, presenter, {})
      expect(activity.vtext_linker).to eq vtext_linker
    end
  end
end
