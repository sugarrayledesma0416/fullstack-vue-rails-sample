RSpec.describe OneRoster::UnlinkedResource, type: :model do
  let(:instructor) { create(:instructor) }
  let(:school_salesforce_id) { SecureRandom.uuid }
  let(:district) { create(:district) }
  let(:school) { create(:school, district: district, salesforce_id: school_salesforce_id) }
  let(:unlinked_section) do
    {
      'sourced_id' => SecureRandom.uuid,
      'title' => 'Class title 3',
      'school_salesforce_id' => '',
      'academic_sessions' => [],
      'course_title' => 'Course title 3',
      'course_sourced_id' => SecureRandom.uuid,
      'm3_section' => nil,
      'start_date' => nil,
      'end_date' => nil,
      'school' => nil
    }
  end
  let(:available_sections) do
    [
      {
        'sourced_id' => SecureRandom.uuid,
        'title' => 'Class title 1',
        'school_salesforce_id' => school_salesforce_id,
        'academic_sessions' => [],
        'course_title' => 'Course title 1',
        'course_sourced_id' => SecureRandom.uuid,
        'm3_section' => nil,
        'start_date' => nil,
        'end_date' => nil,
        'school' => school
      },
      {
        'sourced_id' => SecureRandom.uuid,
        'title' => 'Class title 2',
        'school_salesforce_id' => school_salesforce_id,
        'academic_sessions' => [],
        'course_title' => 'Course title 2',
        'course_sourced_id' => SecureRandom.uuid,
        'm3_section' => nil,
        'start_date' => nil,
        'end_date' => nil,
        'school' => school
      }
    ]
  end

  describe '#log_sections_without_school' do
    let(:unlinked_resource_object) do
      described_class.new(sections: available_sections, user: instructor)
    end

    before do
      allow(unlinked_resource_object).to receive(:dispatch).and_return(nil)
    end

    context 'when there are not sections with missing school' do
      it 'does not dispatch the log' do
        unlinked_resource_object.log_sections_without_school

        expect(unlinked_resource_object).not_to have_received(:dispatch)
      end
    end

    context 'when there are sections with missing school' do
      let(:user_info) do
        {
          guid: instructor.guid,
          first_name: instructor.first_name,
          last_name: instructor.last_name
        }
      end
      let(:payload) do
        {
          payload: [
            {
              school_name: instructor.one_roster_linked_user.school.name,
              class_id: unlinked_section['sourced_id'],
              course_id: unlinked_section['course_sourced_id'],
              course_name: unlinked_section['course_title'],
              instructor: user_info
            }
          ]
        }
      end

      before do
        available_sections << unlinked_section
        school.instructors << instructor
        create(:one_roster_linked_user, school: school, user: instructor)
      end

      it 'dispatches the log' do
        unlinked_resource_object.log_sections_without_school

        expect(unlinked_resource_object).to have_received(:dispatch).with(
          payload: payload,
          stats_index: 'ra-classes-missing-school-log',
          stats_type: :warning_log
        )
      end
    end
  end
end
