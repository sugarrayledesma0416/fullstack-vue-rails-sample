describe InstructorResourceSetting do

  describe ".destroy_old_settings" do
    before(:each) do
      @instructor = create(:instructor)
      @program = create(:program)
      @resource = create(:resource, :program_id => @program.id)
      @instructor_resource_setting = create(:instructor_resource_setting, :resource => @resource, :instructor => @instructor)
    end

    it "should remove previous saved settings for the resource" do
      @instructor_resource_setting.destroy_old_settings
      old_settings = InstructorResourceSetting.all_by_user_id_and_resource_id(@instructor.id, @resource.id)
      expect(old_settings.to_a).to eql []
    end
  end

  describe ".all_by_user_id_and_resource_id" do
    before(:each) do
      @instructor = create(:instructor)
      @program = create(:program)
      @resource = create(:resource, :program_id => @program.id)
      @instructor_resource_setting = create(:instructor_resource_setting, :resource => @resource, :instructor => @instructor)
    end

    it "should return a list of resource settings" do
      resource_settings = InstructorResourceSetting.all_by_user_id_and_resource_id(@instructor.id, @resource.id)
      expect(resource_settings.to_a).to eql [@instructor_resource_setting]
    end
  end
end
