describe CourseLicenseCreatorWorker do
  describe '#perform' do
    let(:course)      { build_stubbed(:course) }
    let(:valid_params) { [course.guid, [1,2,3]] }
    let(:license_creator)     { double('CourseLicenseCreator', :create_licenses => true) }

    before do
      allow(CourseLicenseCreator).to receive(:new).and_return(license_creator)
    end

    it 'calls create_course_license on a new CourseLicenseCreator instance' do
      expect(license_creator).to receive(:create_license).and_return(true)
      CourseLicenseCreatorWorker.new.perform(*valid_params)
    end

  end
end
