describe OneRoster::CourseSectionUpdater do
  let(:program) { create(:program_with_lessons) }
  let(:instructor) { create(:instructor) }
  let(:course_external_id) { SecureRandom.uuid }
  let(:class1_external_id) { SecureRandom.uuid }
  let(:class2_external_id) { SecureRandom.uuid }
  let(:school_salesforce_id) { SecureRandom.uuid }
  let(:start_date) { 2.days.ago }
  let(:start_date_str) { start_date.strftime(OneRoster::CourseSectionUpdater::DATE_FORMAT) }
  let(:end_date) { 2.months.from_now }
  let(:end_date_str) { end_date.strftime(OneRoster::CourseSectionUpdater::DATE_FORMAT) }
  let(:new_start_date) { 1.day.from_now }
  let(:new_start_date_str) { new_start_date.strftime(OneRoster::CourseSectionUpdater::DATE_FORMAT) }
  let(:new_end_date) { 3.months.from_now }
  let(:new_end_date_str) { new_end_date.strftime(OneRoster::CourseSectionUpdater::DATE_FORMAT) }
  let(:school) { create(:one_roster_school, salesforce_id: school_salesforce_id) }
  let(:course1) do
    create(:course,
     name: 'Spanish 1',
     school: school,
     program: program,
     owner: instructor,
     start_date: start_date,
     end_date: end_date)
  end

  let(:course2) do
    create(:course,
     name: 'Spanish 1',
     school: school,
     program: program,
     owner: instructor,
     start_date: start_date,
     end_date: end_date)
  end

  let!(:section1) { create(:section, instructor: instructor, name: 'RA Section 1', course: course1) }
  let!(:linked_section1) { create(:one_roster_linked_section, course_external_id: course_external_id, class_external_id: class1_external_id, section: section1, school: school) }

  let!(:section2) { create(:section, instructor: instructor, name: 'RA Section 2', course: course2) }
  let!(:linked_section2) { create(:one_roster_linked_section, course_external_id: course_external_id, class_external_id: class2_external_id, section: section2, school: school) }

  let(:roster_assistant_data) do
      [
        {
          'course_title' => 'AP Spanish 1',
          'sourced_id' => class1_external_id,
          'title' => 'AP Spanish Section 1',
          'school_salesforce_id' => school.salesforce_id,
          'academic_sessions' => [
            {
              'start_date' => new_start_date_str,
              'end_date' => end_date_str,
              'school_year' => end_date.year.to_s
              }
            ]
        },
        {
          'course_title' => 'AP Spanish 1',
          'sourced_id' => class2_external_id,
          'title' => 'AP Spanish Section 2',
          'school_salesforce_id' => school.salesforce_id,
          'academic_sessions' => [
            {
              'start_date' => start_date_str,
              'end_date' => new_end_date_str,
              'school_year' =>  end_date.year.to_s
            }
          ]
        }
      ]
  end

  let(:missing_class_roster_assistant_data) do
   [
      {
        'course_title' => 'AP Spanish 1',
        'sourced_id' => class1_external_id,
        'title' => 'AP Spanish Section 1',
        'school_salesforce_id' => school.salesforce_id,
        'academic_sessions' => [
          {
            'start_date' => new_start_date.strftime(OneRoster::CourseSectionUpdater::DATE_FORMAT),
            'end_date' => end_date.strftime(OneRoster::CourseSectionUpdater::DATE_FORMAT),
            'school_year' => end_date.year.to_s
          }
        ]
      }
   ]
  end

  let(:extra_class_roster_assistant_data) do
    [
        {
          'course_title' => 'AP Spanish 1',
          'sourced_id' => class1_external_id,
          'title' => 'AP Spanish Section 1',
          'school_salesforce_id' => school.salesforce_id,
          'academic_sessions' => [
            {
              'start_date' => new_start_date_str,
              'end_date' => end_date_str,
              'school_year' => end_date.year.to_s
            }
          ]
        },
        {
          'course_title' => 'AP Spanish 1',
          'sourced_id' => class2_external_id,
          'title' => 'AP Spanish Section 2',
          'school_salesforce_id' => school.salesforce_id,
          'academic_sessions' => [
             {
               'start_date' => start_date_str,
               'end_date' => new_end_date_str,
               'school_year' =>  end_date.year.to_s
             }
          ]
        },
        {
          'course_title' => 'AP Spanish 1',
          'sourced_id' => SecureRandom.uuid,
          'title' => 'AP Spanish Section 2',
          'school_salesforce_id' => school.salesforce_id,
          'academic_sessions' => [
            {
              'start_date' => start_date_str,
              'end_date' => end_date_str,
              'school_year' =>  end_date.year.to_s
            }
          ]
        }
        ]
  end

  let(:roster_assistant_client) do
    instance_double(OneRoster::Client, classes_for_course: roster_assistant_data,
                                       last_request_successful?: true)
  end

  let(:updater) { described_class.new(school.id, course_external_id) }
  let(:expected_ua_params) do
   [
     {
       section_guid: linked_section1.section.guid,
       external_class_id: class1_external_id
     },
     {
       section_guid: linked_section2.section.guid,
       external_class_id: class2_external_id
     }
   ]
  end

  before do
    create(:one_roster_linked_user, user: instructor, school: school)
    allow(OneRoster::Client).to receive(:new).and_return(roster_assistant_client)
    allow(Ua::OneRosterEnrollments).to receive(:create)
    allow(Rails.logger).to receive(:warn)
  end

  describe '#update' do
    it 'updates linked sections with info retrieved from RosterAssistant' do
      updater.update
      expect(linked_section1.section.reload.name).to eql('AP Spanish Section 1')
      expect(linked_section2.section.reload.name).to eql('AP Spanish Section 2')
      expect(linked_section1.section.course.reload).to have_attributes(
        name: 'AP Spanish 1',
        start_date: Date.strptime(new_start_date.to_s),
        end_date: Date.strptime(end_date.to_s)
      )
      expect(linked_section2.section.course.reload).to have_attributes(
        name: 'AP Spanish 1',
        start_date: Date.strptime(start_date.to_s),
        end_date: Date.strptime(new_end_date.to_s)
      )
    end

    context 'when a course is closed,' do
      let(:course1) do
        create(
          :closed_course,
          name: 'Spanish 1',
          school: school,
          program: program,
          owner: instructor
        )
      end

      it 'does not update the course and section attributes' do
        expect do
          updater.update
        end.to not_change { course1.reload.attributes }
          .and not_change { section1.reload.attributes }

        expect(section2.reload.name).to eql('AP Spanish Section 2')
        expect(course2.reload).to have_attributes(
          name: 'AP Spanish 1',
          start_date: Date.strptime(start_date.to_s),
          end_date: Date.strptime(new_end_date.to_s)
        )
      end
    end

    it 'does not update a section that has same course_external_id but it is in a different school' do
      other_school = create(:one_roster_school, salesforce_id: school_salesforce_id)
      original_section_name = 'Other School Section'
      other_section = create(:section, instructor: instructor, name: original_section_name)
      create(:one_roster_linked_section, course_external_id: course_external_id, class_external_id: class1_external_id, section: other_section, school: other_school)
      linked_section1.destroy! # Removing the linked section with the same course_external_id to ensure that we hit the expected case.
      updater.update
      expect(other_section.reload.name).to eq original_section_name
    end

  let!(:section1) { create(:section, instructor: instructor, name: 'RA Section 1', course: course1) }
  let!(:linked_section1) { create(:one_roster_linked_section, course_external_id: course_external_id, class_external_id: class1_external_id, section: section1, school: school) }

    it 'does not trigger the update callbacks if the section name has not changed' do
      roster_assistant_data[0]['title'] = section1.name
      roster_assistant_data[1]['title'] = section2.name
      expect_any_instance_of(Section).not_to receive(:save)
      updater.update
    end

    it 'does not trigger the update callbacks if the course name and dates have not changed' do
      roster_assistant_data[0]['course_title'] = course1.name
      roster_assistant_data[0]['academic_sessions'][0]['start_date'] = course1.start_date.strftime(OneRoster::CourseSectionUpdater::DATE_FORMAT)
      roster_assistant_data[0]['academic_sessions'][0]['end_date'] = course1.end_date.strftime(OneRoster::CourseSectionUpdater::DATE_FORMAT)
      roster_assistant_data[1]['course_title'] = course2.name
      roster_assistant_data[1]['academic_sessions'][0]['start_date'] = course2.start_date.strftime(OneRoster::CourseSectionUpdater::DATE_FORMAT)
      roster_assistant_data[1]['academic_sessions'][0]['end_date'] = course2.end_date.strftime(OneRoster::CourseSectionUpdater::DATE_FORMAT)
      expect_any_instance_of(Course).not_to receive(:save)
      updater.update
    end

    it 'archives any course/section/linked_section that no longer comes from RosterAssistant if end_date is more than 7 days from now' do
      allow(roster_assistant_client).to receive(:classes_for_course)
        .and_return(missing_class_roster_assistant_data)
      section = linked_section2.section
      course = linked_section2.section.course
      updater.update
      expect(OneRoster::LinkedSection.find_by(class_external_id: class2_external_id)).to be_nil
      expect(section.reload).to be_archived
      expect(course.reload).to be_archived
    end

    it 'does not archive any course/section/linked_section that no longer comes from RosterAssistant if end_date is less than 7 days from now' do
      allow(roster_assistant_client).to receive(:classes_for_course)
        .and_return(missing_class_roster_assistant_data)
      section = linked_section2.section
      course = linked_section2.section.course
      course.update!(end_date: 6.days.from_now)
      updater.update
      expect(OneRoster::LinkedSection.find_by(class_external_id: class2_external_id)).not_to be_nil
      expect(section.reload).not_to be_archived
      expect(course.reload).not_to be_archived
    end

    it 'ignores classes from RA that are not yet created' do
      allow(roster_assistant_client).to receive(:classes_for_course)
        .and_return(extra_class_roster_assistant_data)
      updater.update
      # 3rd class returned in the RA data is ignored
      expect do
        updater.update
      end.not_to change(OneRoster::LinkedSection, :count)
    end

    it 'reports errors for any deletion failure' do
      allow_any_instance_of(Section).to receive(:update)
        .with(name: 'AP Spanish Section 1').and_call_original
      allow_any_instance_of(Section).to receive(:update)
        .with(is_archived: true).and_return(false)
      allow(roster_assistant_client).to receive(:classes_for_course)
        .and_return(missing_class_roster_assistant_data)
      updater.update
      expect(updater.errors.flatten).to match_array(      ["Section deletion failed. Please try again in a few minutes. If you continue to see this error, please contact technical support."])
    end

    it "notifies UA to update the linked section's enrollments" do
      updater.update
      expect(Ua::OneRosterEnrollments).to have_received(:create).with(sections: expected_ua_params)
    end

    it "logs a warning if the call to UA fails" do
      allow(Ua::OneRosterEnrollments).to receive(:create).and_raise(ActiveResource::ServerError, nil)
      updater.update
      expect(Rails.logger).to have_received(:warn)
                             .with("UA returned bad response: Failed. during enrollments update for #{expected_ua_params}")
    end
  end
end
