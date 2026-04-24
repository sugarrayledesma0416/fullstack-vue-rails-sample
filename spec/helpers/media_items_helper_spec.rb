describe MediaItemsHelper do

  describe "#format_popup_play_link" do
    context "always," do
      before(:each) do
        @media_item = build_stubbed(:media_item, :media_type => 'image')
        expect(helper).to receive(:format_popup_onclick).and_return('valid_popup')
      end

      it "returns a popup link to display the media item" do
        result = helper.format_popup_play_link(@media_item)
        expect(result).to have_selector("a[href='#{media_item_path(@media_item)}'][onclick='valid_popup']", text: 'Play' )
      end

      it "sets the text of the link, if specified" do
        result = helper.format_popup_play_link(@media_item, 'link_text')
        expect(result).to have_selector("a[href='#{media_item_path(@media_item)}'][onclick='valid_popup']", text: 'link_text' )
      end
    end

    context "when the media item is audio," do
      it "sets the popup dimensions to standard audio dimensions" do
        @media_item = build_stubbed(:media_item, :media_type => 'audio')
        expected = {:window_name => "play_#{@media_item.id}", :height => 60, :width => 180}
        expect(helper).to receive(:format_popup_onclick).with(expected).and_return('valid_popup')
        result = helper.format_popup_play_link(@media_item)
      end
    end

    context "when the media item is video or image," do
      context "when the media item has valid height and width attributes," do
        it "sets the popup dimensions to media_item dimensions plus constants" do
          @media_item = build_stubbed(:media_item, :media_type => 'image', :height => 100, :width => 200)
          expected = {:window_name => "play_#{@media_item.id}", :height => @media_item.height+40, :width => @media_item.width+20}
          expect(helper).to receive(:format_popup_onclick).with(expected).and_return('valid_popup')
          result = helper.format_popup_play_link(@media_item)
        end
      end

      it "sets default values if height is 0" do
        @media_item = build_stubbed(:media_item, :media_type => 'video', :height => 0, :width => 200)
        expected = {:window_name => "play_#{@media_item.id}", :height => 740, :width => 720}
        expect(helper).to receive(:format_popup_onclick).with(expected).and_return('valid_popup')
        result = helper.format_popup_play_link(@media_item)
      end

      it "sets default values if width is 0" do
        @media_item = build_stubbed(:media_item, :media_type => 'image', :height => 100, :width => 0)
        expected = {:window_name => "play_#{@media_item.id}", :height => 740, :width => 720}
        expect(helper).to receive(:format_popup_onclick).with(expected).and_return('valid_popup')
        result = helper.format_popup_play_link(@media_item)
      end

      it "sets default values if height is nil" do
        @media_item = build_stubbed(:media_item, :media_type => 'video', :height => nil, :width => 200)
        expected = {:window_name => "play_#{@media_item.id}", :height => 740, :width => 720}
        expect(helper).to receive(:format_popup_onclick).with(expected).and_return('valid_popup')
        result = helper.format_popup_play_link(@media_item)
      end

      it "sets default values if width is blank" do
        @media_item = build_stubbed(:media_item, :media_type => 'image', :height => 100, :width => '')
        expected = {:window_name => "play_#{@media_item.id}", :height => 740, :width => 720}
        expect(helper).to receive(:format_popup_onclick).with(expected).and_return('valid_popup')
        result = helper.format_popup_play_link(@media_item)
      end

    end
  end

  describe "#display_media_item" do
    it "raises an error if media_item is nil" do
      expect { helper.display_media_item(nil) }
        .to raise_error(RuntimeError, 'given nil media_item')
    end

    it "raises an error if media_type cannot be displayed" do
      media_item = build_stubbed(:media_item, :media_type => 'invalid_type')
      expect { helper.display_media_item(media_item) }
        .to raise_error(RuntimeError, "unsupported media type: 'invalid_type'")
    end

    it "displays an audio partial for audio files" do
      media_item = build_stubbed(:media_item, media_type: 'audio')

      expect(helper).to receive(:render).with(
        'media_items/audio_player',
        auto_play: 0,
        media_item: media_item,
        reference: :bar,
        reference_in_artifact: nil,
        submission_status: :foo
      )

      helper.display_media_item(
        media_item,
        reference: :bar,
        submission_status: :foo
      )
    end

    it "displays a video partial for video files" do
      media_item = build_stubbed(:media_item, :media_type => 'video')
      expect(helper).to receive(:render).with(partial: 'media_items/video_player',
                                               locals: { media_item: media_item,
                                                         record_button_for_question: nil,
                                                         reference: nil})
      helper.display_media_item(media_item)
    end

    context "when a param called record_button_for_question is specified" do
      it "passes the value of that param to the video_player partial" do
        media_item = build_stubbed(:media_item, :media_type => 'video')
        options = { :record_button_for_question => 'question_1' }
        expect(helper).to receive(:render).with({ :partial => 'media_items/video_player',
                                            :locals => { media_item: media_item,
                                                         record_button_for_question: options[:record_button_for_question],
                                                         reference: nil }
                                          })
        helper.display_media_item(media_item, options)
      end
    end

    it 'displays an image tag for image files without long description' do
      media_item = build_stubbed(:media_item, media_type: 'image', width: 10, height: 20)
      allow(media_item).to receive(:public_filename).and_return('image_public_file_name')
      allow(helper).to receive(:image_tag).and_return('<image/>')
      helper.display_media_item(media_item)

      expect(helper).to have_received(:image_tag).with(
        media_item.public_filename,
        {
          width: 10,
          height: 20,
          alt: nil
        }
      )
    end

    it 'renders a partial for image files with long description' do
      options = {
        alt_tag: 'This is an alt tag',
        height: 10,
        long_description: 'This is a pretty long description, as you might already know.',
        media_type: 'image',
        width: 10
      }

      media_item = create(:media_item, options)

      image_options = options.merge(
        alt: media_item.alt_tag,
        'aria-details' => "longdesc-for-#{media_item.id}"
      ).except(:alt_tag, :long_description, :media_type)

      expect(helper).to receive(:render)
        .with(
          partial: 'media_items/images',
          locals: { media_item:, image_options: }
        ).and_return('<div>mocked image html</div>')

      helper.display_media_item(media_item)
    end

    it 'includes additional html attributes if they are specified' do
      media_item = build_stubbed(:media_item, :media_type => 'image')
      allow(media_item).to receive(:public_filename).and_return('image_public_file_name')
      allow(helper).to receive(:image_tag).and_return('<image/>')
      helper.display_media_item(media_item, {:alt => 'valid_alt_text'})

      expect(helper).to have_received(:image_tag).with(
        media_item.public_filename,
        {
          width: nil,
          height: nil,
          alt: 'valid_alt_text'
        }
      )
    end
  end

  describe "#next_audio_player_id" do
    it "returns and unique id with postfix zero on the first call" do
      expect(helper.next_audio_player_id).to eql "audio0"
    end

    it "returns an id with an incrementing postfix" do
      helper.next_audio_player_id
      expect(helper.next_audio_player_id).to eql "audio1"
      expect(helper.next_audio_player_id).to eql "audio2"
    end
  end

end
