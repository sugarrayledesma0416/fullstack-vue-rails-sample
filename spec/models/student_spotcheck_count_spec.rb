describe StudentSpotcheckCount, type: :model do
  describe '.create_or_update' do
    let(:section) { create(:section) }
    let(:students) { create_list(:student, 3) }

    it 'creates a new record with count 1 if it does not exist' do
      student_ids = students.map(&:id)
      StudentSpotcheckCount.create_or_update(student_ids, section.id)

      students.each do |student|
        spotcheck_count = StudentSpotcheckCount.find_by(user_id: student.id, section_id: section.id)
        expect(spotcheck_count).not_to be_nil
        expect(spotcheck_count.count).to eq(1)
      end
    end

    it 'increments the count by 1 if the record exists' do
      student_ids = students.map(&:id)

      StudentSpotcheckCount.create_or_update(student_ids, section.id)
      StudentSpotcheckCount.create_or_update(student_ids, section.id)

      students.each do |student|
        spotcheck_count = StudentSpotcheckCount.find_by(user_id: student.id, section_id: section.id)
        expect(spotcheck_count.count).to eq(2)
      end
    end

    it 'handles a mix of existing and new records' do
      existing_student = students.first
      new_students = students[1..]

      StudentSpotcheckCount.create_or_update([existing_student.id], section.id)
      StudentSpotcheckCount.create_or_update(students.map(&:id), section.id)

      spotcheck_count_existing =
        StudentSpotcheckCount.find_by(user_id: existing_student.id, section_id: section.id)
      expect(spotcheck_count_existing.count).to eq(2)

      new_students.each do |student|
        spotcheck_count = StudentSpotcheckCount.find_by(user_id: student.id, section_id: section.id)
        expect(spotcheck_count.count).to eq(1)
      end
    end
  end
end
