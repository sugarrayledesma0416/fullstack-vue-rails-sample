describe Setting::Collection do
  describe "#get" do
    it "should return nil for nonsense settings" do
      user = create(:user)
      settings_set = Setting::Collection.new(user)
      value = settings_set.get("nonsense")
      expect(value).to be_nil
    end

    it "should return the default value of sensible values if not set" do
      user = create(:user)
      settings_set = Setting::Collection.new(user)
      value = settings_set.get(Setting::Gradebook::CategoryView)
      expect(value).to eql(Setting.default(Setting::Gradebook::CategoryView))
    end

    it "should return the setting value if set" do
      user = create(:user)
      create(:setting, :user => user, :name => "some arbitrary name", :value => "value")
      settings_set = Setting::Collection.new(user)
      value = settings_set.get("some arbitrary name")
      expect(value).to eql("value")
    end

    it "should be able to use symbols to look up values" do
      user = create(:user)
      create(:setting, :user => user, :name => "collection_symbol", :value => "value")
      settings_set = Setting::Collection.new(user)
      value = settings_set.get(:collection_symbol)
      expect(value).to eql("value")
    end
  end

  describe "#set" do
    it "should create the value in the database if it doesn't exist" do
      user = create(:user)
      expect(Setting).to receive(:create!).with(hash_including(:name => "something_nice", :value => "value"))
      settings_set = Setting::Collection.new(user)

      settings_set.set("something_nice", "value")
    end

    it "should update the value in the database if it already exists" do
      setting = build_stubbed(:setting)
      user = create(:user)
      allow(user).to receive(:settings).and_return([setting])
      settings_set = Setting::Collection.new(user)
      expect(setting).to receive(:value=)
      expect(setting).to receive(:save!)

      settings_set.set(setting.name, "value")
    end

    it "should sanitize the value if name is passed as a Definition instance" do
      class Def < Setting::Definition; end

      expect(Def).to receive(:sanitize_value)

      user = create(:user)
      settings_set = Setting::Collection.new(user)
      settings_set.set(Def, "value")
    end

    it "should return a Setting object" do
      class ReturnValue < Setting::Definition; end

      user = create(:user)
      settings_set = Setting::Collection.new(user)
      result = settings_set.set(ReturnValue, "value")
      expect(result).to be_a Setting
    end

    it "should allow retrieval of a value immediately after setting" do
      class ImmediatelyAvailable < Setting::Definition; end

      user = create(:user)
      settings_set = Setting::Collection.new(user)
      settings_set.set(ImmediatelyAvailable, "value")
      result = settings_set.get(ImmediatelyAvailable)
      expect(result).to eql "value"
    end

    it "should use the Definition symbol lookup to apply validations " do
      class CollectionSymbol < Setting::Definition; end

      expect(CollectionSymbol).to receive(:sanitize_value)

      user = create(:user)
      settings_set = Setting::Collection.new(user)
      settings_set.set(:collection_symbol, "value")
    end

  end
end
