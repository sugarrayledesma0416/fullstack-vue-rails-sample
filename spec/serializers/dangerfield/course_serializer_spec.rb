describe CourseSerializer do
  let (:dangerfield_serializer) { described_class.new(Course) }
  let(:owner) { create(:instructor) }
  let(:school) { create(:school) }
  before do
    @program = build_stubbed(:program)
    @unit_1 = create(:unit, :program => @program, :rank => 1)
    @unit_2 = create(:unit, :program => @program, :rank => 2)
    expect(@program).to receive(:unit_label).and_return('unit').at_least(:once)


    @params = {:name => 'valid_name', :program => @program,
               :owner_id => owner.id, :school_id => school.id,
               :first_unit => @unit_1, :last_unit => @unit_2 }
      @params.merge!(end_date: 10.days.from_now, start_date: 10.days.ago)
  end

  describe "dangerfield serializer" do
    before do
      @course = Course.create(@params)
      owner = User.find(@course.owner_id)
      school =  School.find(@course.school_id)
      @course.owner = owner
      @course.school = school
    end

    it "validates that owner_guid is injected into serialized object" do
      course_json = JSON.parse(@course.dangerfield_serializer.to_json)
      expect(course_json["owner_guid"]).to eql(owner.guid)
    end

    it "validates that school_guid is injected into serialized object" do
      course_json = JSON.parse(@course.dangerfield_serializer.to_json)
      expect(course_json["school_guid"]).to eql(school.guid)
    end
  end
end
