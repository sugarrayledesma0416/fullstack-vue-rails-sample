describe UnassignedSectionsLookup do
  let(:activity_1) { create(:activity) }
  let(:course) { create(:course) }
  let(:section_1) { create(:section, course_id: course.id) }

  let(:consumer_klass) do
    Class.new do
      include UnassignedSectionsLookup
      delegate :sections, to: :@course

      def initialize(activity, course)
        @activity = activity
        @course = course
      end

      def activity_assignments(_)
        @activity.assignments
      end
    end
  end

  describe '#unassigned_sections' do
    it 'returns the sections without assignments' do
      create(:section, course_id: course.id)
      create(:assignment, assignable: activity_1, section_id: section_1.id)
      consumer = consumer_klass.new(activity_1, course)
      expect(consumer.unassigned_sections(activity_1.id)).to eq(course.sections - [section_1])
    end
  end
end
