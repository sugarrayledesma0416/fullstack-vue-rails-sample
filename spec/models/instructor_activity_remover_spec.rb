RSpec.describe InstructorActivityRemover do
  subject(:remover) { described_class.new(activity) }

  let(:instructor) { create(:instructor) }
  let(:program) { create(:program_with_toc_entries) }
  let(:course) { create(:course, owner: instructor, program:) }
  let(:section) { create(:section, course:, instructor:) }
  let(:lesson) { program.units.first.lessons.first }
  let(:strand) { lesson.strands.first }

  let(:activity) do
    create(:instructor_created_activity, instructor:, lesson:, toc_location: strand.location)
  end

  before do
    allow(Maestro::LicenseGroup).to receive(:all)
      .and_return([Maestro::LicenseGroup.new('name' => '01-Supersite')])
    create(:concept, id: strand.location, lesson:, program:)
    create(:assignment, assignable: activity, section:)
    create(:course_library_activity, activity:, course:)
    create(:custom_rubric, instructor_created_activity: activity)
  end

  describe '#initialize' do
    it 'initializes properly' do
      expect(remover).not_to be_successful
      expect(remover.message).to be_nil
    end
  end

  describe '#remove' do
    context 'when successful' do
      it 'removes the activity properly' do
        remover.remove

        expect(activity.reload.assignments).to be_empty
        expect(activity.course_library_activities).to be_empty
        expect(activity.custom_rubrics).to be_empty
        expect(activity.hide_from_my_content).to be_truthy
        expect(remover).to be_successful
        expect(remover.message).to eq("Content successfully deleted.")
      end
    end

    context 'when there is an error' do
      let(:error) { ActiveRecord::RecordInvalid.new }

      before do
        allow(activity).to receive(:update!).and_raise(error)
        allow(VHLMonitor).to receive(:notify)
      end

      it 'handles the error properly' do
        remover.remove

        expect(activity.reload.assignments).not_to be_empty
        expect(activity.course_library_activities).not_to be_empty
        expect(activity.custom_rubrics).not_to be_empty
        expect(activity.hide_from_my_content).to be_falsey
        expect(remover).not_to be_successful
        expect(remover.message).to eq('Content could not be deleted.')
        expect(VHLMonitor).to have_received(:notify).with(error)
      end
    end
  end
end
