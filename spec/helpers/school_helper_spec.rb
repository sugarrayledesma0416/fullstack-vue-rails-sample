describe SchoolHelper do
  include SchoolHelper
  describe "#format_school_label" do

    it "returns the name, city, and state of the school by default" do
      school = build_stubbed(:school, :name => 'School', :city => 'City', :state => 'MA')

      expect(format_school_label(school)).to eql("School, City, MA")
    end

    it "does not show the state for international schools" do
      school = build_stubbed(:school, :state => 'ZZ')
      allow(school).to receive(:country_name).and_return('FakeCountry')

      expect(format_school_label(school)).not_to include("ZZ")
    end

    it "shows the country for international schools" do
      school = build_stubbed(:school, :state => 'ZZ')
      allow(school).to receive(:country_name).and_return('FakeCountry')

      expect(format_school_label(school)).to include("FakeCountry")
    end

  end

  describe "#format_school_select" do
    it "should return a two dimension array containing a name and an id" do
      school = double(School)
      allow(school).to receive(:name).and_return('FakeSchool')
      allow(school).to receive(:id).and_return(1234)

      results = format_school_select([school], course = nil)

      expect(results).to be_a Array
      expect(results.size).to eql 1
      expect(results.first).to eql ['FakeSchool', 1234]

    end
  end

  describe "#should_format_by_schools? " do
    it "should return true if the courses array element count is greater than 1" do
      expect(should_format_by_schools?([1, 2, 3, 4, 5])).to eql true
      expect(should_format_by_schools?([4, 5])).to eql true
    end

    it "should return false if the courses array is empty" do
      expect(should_format_by_schools?([])).to eql false
    end

    it "should return false if the courses array contains only one element" do
      expect(should_format_by_schools?([2])).to eql false
    end

  end
end
