describe "a help entry" do
  context "with valid attributes" do
    before(:each) do
      @help_entry_attributes = {:page => 'home#front', :url => 'http://example.com'}
      @help_entry = create(:help_entry, @help_entry_attributes)
    end

    it "should expose page" do
      expect(@help_entry.page).to eq(@help_entry_attributes[:page])
    end

    it "should expose url" do
      expect(@help_entry.url).to eq(@help_entry_attributes[:url])
    end

    it "should accept namespaced routes" do
      @help_entry.page = "gradebook/email#list"
      expect(@help_entry.save).to be_truthy
    end
  end

  describe "#published?" do
    it "returns true if help_entry is published" do
      help_entry = create(:help_entry, :published => true, :page => 'home#front', :url => 'http://example.com')
      expect(help_entry.published?).to be_truthy
    end

    it "returns false if help_entry is not published" do
      help_entry = create(:help_entry, :published => false, :page => 'home#front', :url => 'http://example.com')
      expect(help_entry.published?).to be_falsey
    end
  end

  context "with invalid attributes" do
    it "should require a page" do
      expect do
        create(:help_entry, :page => nil, :url => 'example.com')
      end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Page is required')
    end

    it "should require a url" do
      expect do
        create(:help_entry, :page => 'activities#show', :url => nil)
      end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Url is required')
    end

    it "should require a unique page" do
      create(:help_entry, :page => 'home#front', :url => 'example.com')
      expect do
        create(:help_entry, :page => 'home#front', :url => 'example.com')
      end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Page has already been used')
    end

    it "should require a well-formed controller/action pair" do
      expect do
        create(:help_entry, :page => 'home/front', :url => 'example.com')
      end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Page must be in the format "controller#action"')
    end

    it "should require a controller that exists" do
      expect do
        create(:help_entry, :page => 'foo#bar', :url => 'example.com')
      end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Page controller does not exist')
    end

    it "should require an action that exists" do
      expect do
        create(:help_entry, :page => 'activities#foo', :url => 'example.com')
      end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Page action does not exist')
    end

    it "should require a valid url" do
      expect do
        create(:help_entry, :page => 'home#front', :url => 'as df')
      end.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Url format is not valid')
    end

  end

  context "with attributes requiring cleanup" do
    it "should prepend URLs with http:// if they do not have it" do
      @help_entry_attributes = {:page => 'home#front', :url => 'rspec.info'}
      @help_entry = create(:help_entry, @help_entry_attributes)
      expect(@help_entry.url).to eq('http://rspec.info')
    end

    it "should not prepend URLs with http:// if they do have it" do
      @help_entry_attributes = {:page => 'home#front', :url => 'http://example.com'}
      @help_entry = create(:help_entry, @help_entry_attributes)
      expect(@help_entry.url).to eq('http://example.com')
    end

    it "does not prepend URLs with http:// if they have https://" do
      @help_entry_attributes = { page: 'home#front', url: 'https://example.com' }
      @help_entry = create(:help_entry, @help_entry_attributes)
      expect(@help_entry.url).to eq  'https://example.com'
    end
  end
end
