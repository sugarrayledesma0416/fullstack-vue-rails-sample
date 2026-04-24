describe DemoCourseCreatorWorker do
  describe '#perform' do
    it 'calls create_course on a new DemoCourseBuild::Creator instance' do
      demo_course_creator = instance_double(DemoCourseBuild::Creator, create_course: true)
      allow(DemoCourseBuild::Creator).to receive(:new).and_return(demo_course_creator)
      described_class.new.perform({})

      expect(demo_course_creator).to have_received(:create_course)
    end

    it 'raises an exception if the process has errors' do
      demo_course_creator = instance_double(
        DemoCourseBuild::Creator,
        create_course: false
      )
      allow(demo_course_creator).to receive(:errors).and_return(
        ActiveModel::Errors.new(demo_course_creator)
      )
      demo_course_creator.errors.add(:base, 'something went wrong')
      allow(DemoCourseBuild::Creator).to receive(:new).and_return(demo_course_creator)

      expect { described_class.new.perform({}) }
        .to raise_error(RuntimeError, 'something went wrong')
    end
  end
end
