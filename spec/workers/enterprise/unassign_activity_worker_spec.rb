module Enterprise
  describe UnassignActivityWorker do
    let(:school) { create(:school) }
    let(:program) { create(:program) }
    let(:course_owner) { create(:instructor) }
    let(:co_instructor) { create(:instructor) }
    let(:inst_admin) { create(:institution_admin) }
    let(:section) { create(:section, instructor: course_owner) }
    let(:course) { create(:course, owner: course_owner, program:, school:, sections: [section]) }
    let(:toc_entry) { create(:toc_entry, id: 10) }
    let(:activity) { create(:activity, toc_location: toc_entry.id) }
    let(:activity_assignment) do
      instance_double(
        ActivityAssignment,
        activity:,
        current_user: course_owner,
        program:,
        params: { course_id: course.id }
      )
    end
    let(:worker) { described_class.new }

    before do
      allow(ActivityAssignment).to receive(:new).and_return(activity_assignment)
      allow(activity_assignment).to receive(:unassign)
    end

    context 'when the current instructor is the Institution Admin' do
      it 'unassigns an ActivityAssignment record' do
        worker.perform(activity.id, inst_admin.id, program.id, course.id)
        expect(activity_assignment).to have_received(:unassign)
      end
    end

    context 'when the current instructor is the course owner' do
      it 'unassigns an ActivityAssignment record' do
        worker.perform(activity.id, course_owner.id, program.id, course.id)
        expect(activity_assignment).to have_received(:unassign)
      end
    end

    context 'when the current instructor is a co-instructor' do
      it 'unassigns an ActivityAssignment record' do
        create(:section_co_instructor, section:, instructor: co_instructor)
        worker.perform(activity.id, co_instructor.id, program.id, course.id)
        expect(activity_assignment).to have_received(:unassign)
      end
    end

    context 'when the current instructor is not the Institution Admin or a course instructor' do
      it 'does not unassign an ActivityAssignment record' do
        new_instructor = create(:instructor)
        worker.perform(activity.id, new_instructor.id, program.id, course.id)
        expect(activity_assignment).not_to have_received(:unassign)
      end
    end
  end
end
