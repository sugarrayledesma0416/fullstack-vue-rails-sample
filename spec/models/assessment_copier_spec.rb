describe AssessmentCopier do
  describe '#copy' do
    let(:program) { build_stubbed(:program) }
    let(:lesson) { build_stubbed(:lesson) }
    let(:concept) { build_stubbed(:concept) }
    let(:activity) do
      build_stubbed(
        :activity_with_assignment_group,
        activity_type: 'exam',
        concept: concept,
        lesson: lesson
      )
    end
    let(:instructor) { create(:instructor) }
    let(:toc_entry) { create(:toc_entry, id: 123456) }
    let(:instructor_created_activity) do
      build(:instructor_created_activity, toc_location: toc_entry.id)
    end
    let(:xml_content) { File.read(File.join(Rails.root, 'spec/fixtures/xml', 'exam.xml')) }
    let(:exam_time_estimate) do
      ActivityTimeEstimateSetter.new(activity_type: 'exam').time_to_complete
    end

    context 'copies assessment' do
      before do
        stub_request(:any, /https\:\/\/s3\.amazonaws\.com\/vhlcentral\.activities\/.*\.xml/).
          to_return(:status => 200, :body => xml_content, :headers => {})
        allow(Maestro::LicenseGroup).to receive(:all).and_return([double('LicenseGroup', :id => 100, :name => 'VOL')])
        allow(lesson).to receive(:program).and_return(program)
        allow(InstructorCreatedActivity).to receive(:new).and_return(instructor_created_activity)
        allow(Activity).to receive(:where).and_return([activity])
        allow(activity.activity_content).to receive(:content).and_return(xml_content)
        allow(activity).to receive(:minutes_to_complete).and_return(25)
        allow(instructor_created_activity).to receive(:concept) { concept }
        @processor = AssessmentCopier.new(activity.id, instructor.id).copy
      end

      context 'when activity exists' do
        it 'creates a copy from an activity' do
          expect(@processor.created_activity.concept_id).to be_eql(activity.concept_id)
          expect(@processor.created_activity.title).to be_eql("Copy of #{activity.title}")
          expect(@processor.created_activity.generated_content).to be_eql(activity.content)
          expect(@processor.created_activity.instructor_id).to be_eql(instructor.id)
          expect(@processor.created_activity.activity_type).to be_eql(activity.activity_type)
          expect(@processor.created_activity.icon).to be_eql('audio')
          expect(@processor.created_activity.minutes_to_complete).to be_eql(exam_time_estimate)
          expect(@processor.created_activity.assignment_group).to be_eql(activity.assignment_group)
          expect(@processor.created_activity.content_json).to be_eql(activity.generate_content_json)
        end

        it "sets minutes_to_complete to a default value if original value is null" do
          allow(activity).to receive(:minutes_to_complete).and_return(nil)
          processor = AssessmentCopier.new(activity.id, instructor.id).copy
          expect(processor.created_activity.minutes_to_complete).to be_eql(exam_time_estimate)
        end
      end
    end
  end
end
