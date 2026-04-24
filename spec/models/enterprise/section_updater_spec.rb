describe Enterprise::SectionUpdater do
  subject(:updater) { described_class.new(section_params, section) }

  let(:institution_admin) { create(:institution_admin) }
  let(:enterprise_course) { create(:enterprise_course, owner: institution_admin) }
  let(:enterprise_section) do
    create(:enterprise_section, course: enterprise_course, instructor: institution_admin)
  end
  let(:owner) { create(:instructor) }
  let!(:section) do
    create(:section,
           course: enterprise_course,
           hide_owner_name: false,
           instructor: owner,
           source_template_id: enterprise_section.id,
           name: 'Section Name',
           days_to_show_assignment_due_date: 3,
           due_time: '11:00'
    )
  end
  let!(:instructor_1) { create(:instructor) }
  let!(:instructor_2) { create(:instructor) }
  let!(:instructor_3) { create(:instructor) }
  let!(:instructor_1_section_instructor) { create(:section_instructor, role: 'Assistant', section: section, show: false, user_id: instructor_1.id) }
  let!(:instructor_2_section_instructor) { create(:section_instructor, role: 'Assistant', section: section, show: false, user_id: instructor_2.id) }

  describe '#update_section' do
    context 'when updating section attributes' do
      let(:section_params) do
        {
          id: section.id,
          name: 'Updated Section Name',
          days_to_show_assignment_due_date: 7,
          due_time: '15:00',
          time_zone: 'UTC',
          additional_instructors: [
            { instructor_id: instructor_1.id, role: 'Co-instructor', show: true },
            { instructor_id: instructor_3.id, role: 'Assistant', show: true }
          ]
        }
      end

      before do
        section.reload
        updater.update_section
      end

      it 'updates the section name' do
        expect(section.name).to eq('Updated Section Name')
      end

      it 'updates the days_to_show_assignment_due_date value' do
        expect(section.days_to_show_assignment_due_date).to eq(7)
      end

      it 'updates the due_time value' do
        expected_time = Time.zone.parse('15:00').strftime('%H:%M')

        expect(section.due_time.strftime('%H:%M')).to eq(expected_time)
      end

      it 'updates the time_zone value' do
        expect(section.time_zone).to eq('UTC')
      end
    end

    context 'when updating additional instructors' do
      let(:section_params) do
        {
          id: section.id,
          name: 'new name',
          hide_owner_name: true,
          additional_instructors: [
            { instructor_id: instructor_1.id, role: 'Co-instructor', show: true },
            { instructor_id: instructor_3.id, role: 'Assistant', show: true }
          ]
        }
      end

      before do
        section.reload
        updater.update_section
      end

      it 'adds a new instructor to the section' do
        expect(SectionInstructor.exists?(section: section, user_id: instructor_3.id)).to be(true)
      end

      it 'removes an instructor no longer part of the section' do
        expect(SectionInstructor.exists?(section: section, user_id: instructor_2.id)).to be(false)
      end

      it 'updates the "show" setting for an existing instructor' do
        expect(SectionInstructor.find_by(section: section, user_id: instructor_1.id).show).to be(true)
      end
    end
  end

  describe 'validations' do
    context 'when all instructors are hidden' do
      let(:section_params) do
        {
          id: section.id,
          name: 'new name',
          hide_owner_name: true,
          additional_instructors: [
            { instructor_id: instructor_1.id, role: 'Co-instructor', show: false },
            { instructor_id: instructor_3.id, role: 'Assistant', show: false }
          ]
        }
      end

      it 'raises an error' do
        expect { updater.update_section }.to raise_error('At least one instructor must be shown in section preview.')
      end
    end
  end
end
