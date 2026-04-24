describe FlashcardsActivitiesController do
=begin
  fixtures :users

  describe "GET flashcards_data" do
    context "with vocab group media items" do
      before(:each) do
        login_as(:quentin)
        @flashcards_activity = build_stubbed(:activity)
        Activity.stub(:find).and_return(@flashcards_activity)
        activity_parser = mock(MaestroActivityEngine::ActivityParser)
        MaestroActivityEngine::ActivityParser.stub(:create_parser).and_return(activity_parser)

        @activity_content = mock(MaestroActivityEngine::ActivityContent)
        @activity_content.stub(:number_of_decks).and_return(1)
        activity_parser.stub(:parse).and_return(@activity_content)
      end

      it "should do nothing if the group has no media" do
        group  = MaestroActivityEngine::ActivityContent::VocabList::Group.new(:id => nil)
        @activity_content.stub(:items).and_return([group])

        MediaItem.should_not_receive(:find)
        group.should_not_receive(:base_dir=)
        group.should_not_receive(:public_dir=)
        get :flashcards_data, :id => @flashcards_activity.id, :flashcards_deck_id => 1
      end

      context "when the group has media," do
        before(:each) do
          @media_item = build_stubbed(:media_item, id: 123,
                                                  base_dir: 'base_dir',
                                                  public_dir: 'public_dir')
          @group  = MaestroActivityEngine::ActivityContent::VocabList::Group.new(:id => @media_item.id)
          @group.stub(:populate_content_from_csv)
          @group.stub(:rows).and_return([])
          @activity_content.stub(:items).and_return([@group])
          MediaItem.stub(:find).and_return(@media_item)
        end

        it "should find the media item based on the group id" do
          MediaItem.should_receive(:find).with(@group.id).and_return(@media_item)
          get :flashcards_data, :id => @flashcards_activity.id, :flashcards_deck_id => 1
        end

        it "should assign the unzip dir to the group's base dir" do
          @media_item.should_receive(:temp_dir).and_return('temp_dir')
          @group.should_receive(:base_dir=).with('temp_dir')
          get :flashcards_data, :id => @flashcards_activity.id, :flashcards_deck_id => 1
        end

        it "should assign the public path to the unzip dir to the group's public_dir" do
          @media_item.should_receive(:temp_public_dir).and_return('temp_public_dir')
          @group.should_receive(:public_dir=).with('temp_public_dir')
          get :flashcards_data, :id => @flashcards_activity.id, :flashcards_deck_id => 1
        end

        it "should return a json-formatted list of terms" do
          @group.stub(:breaks).and_return(nil)
          row_1 = {:target_word => 'target word with áççéñts', :native_word => 'base word with áççéñts', :audio_path => 'path/to/file.mp3'}
          row_2 = {:target_word => 'another’s target', :native_word => 'another’s base', :audio_path => 'path/to/other_file.mp3'}
          @group.stub(:rows).and_return([row_1, row_2])

          result = [
                    {:target => 'target word with áççéñts', :base => 'base word with áççéñts', :audio_path => 'path/to/file.mp3'},
                    {:target => 'another’s target', :base => 'another’s base', :audio_path => 'path/to/other_file.mp3'}
                  ]

          get :flashcards_data, :id => @flashcards_activity.id, :flashcards_deck_id => 1
          response.body.should eql result.to_json
        end
      end
    end
  end

  describe "#split_terms_into_decks" do
    it "should divide the terms into decks" do
      terms = [
                ['vocab group name', 'group_audio.mp3'],
                ['target word', 'base word', 'file.mp3'],
                ['another target', 'another base', 'other_file.mp3']
              ]
      controller = FlashcardsActivitiesController.new
      controller.split_terms_into_decks(terms, 2).should eql [ [terms[0], terms[2]], [terms[1]] ]
    end
  end

  describe "#format_terms_from_content" do
    it "should replace terms with matches from the activity content" do
      target_break = {:target => ['target <br/>word ', 'Another<br/>target word']}
      base_break = {:base => [' another<br/> base', 'another<br/>base word']}

      breaks = [target_break, base_break]

      vocab_group = mock(MaestroActivityEngine::ActivityContent::VocabList::Group)
      vocab_group.stub(:breaks).and_return(breaks)

      terms = [
                {:target => 'target word', :base => 'base word', :audio_path => '/unzip_path/file.mp3'},
                {:target => 'another target word', :base => 'another base word', :audio_path => '/unzip_path/another_file.mp3'},
                {:target => 'another target', :base => 'another base', :audio_path => '/unzip_path/other_file.mp3'}
              ]

      save_base = terms.first[:base]
      save_target = terms.last[:target]

      controller = FlashcardsActivitiesController.new
      terms = controller.format_terms_from_content(terms, [vocab_group])

      terms[0][:target].should eql target_break[:target].first.strip
      terms[0][:base].should eql save_base
      terms[1][:target].should eql target_break[:target].last.strip
      terms[1][:base].should eql base_break[:base].last.strip
      terms[2][:target].should eql save_target
      terms[2][:base].should eql base_break[:base].first.strip
    end
  end

  describe "#normalize_key" do
    before(:each) do
      @controller = FlashcardsActivitiesController.new
    end

    it "should remove spaces" do
      input = 'this is a test string'
      @controller.normalize_key(input).should eql 'thisisateststring'
    end

    it "should remove html tags, including the break" do
      input = '<b>this</b> is <br/> a test string'
      @controller.normalize_key(input).should eql 'thisisateststring'
    end

    it "should remove leading and trailing spaces" do
      input = '  this is a test string '
      @controller.normalize_key(input).should eql 'thisisateststring'
    end

    it "should decode html entities" do
      input = 'this is a t&#xE9;st string'
      @controller.normalize_key(input).should eql 'thisisatéststring'
    end
  end
=end
end
