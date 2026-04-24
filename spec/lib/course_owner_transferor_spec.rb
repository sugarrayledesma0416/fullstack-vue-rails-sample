require 'course_owner_transferor'

describe CourseOwnerTransferor do
  let(:owner) { create(:institution_admin) }
  let(:destination_instructor) { create(:instructor) }
  let(:course) { create(:course, owner: owner) }

  describe 'transfer' do
    context 'when the user doing the transfer is not the owner of the course' do
      let(:other_instructor) { create(:instructor) }
      let(:course_owner_transferor) do
        described_class.new(course, other_instructor, destination_instructor)
      end

      it 'does not transfer the course' do
        course_owner_transferor.transfer
        course.reload
        expect(course.owner).to eq owner
      end

      it 'returns false' do
        expect(course_owner_transferor.transfer).to be false
      end

      it 'logs an error of why the course could not be transferred' do
        course_owner_transferor.transfer
        expect(course_owner_transferor.errors).to include 'Only the owner of the course can transfer the course.'
      end
    end

    context 'when the user doing the transfer is not an institution admin' do
      let(:owner) { create(:instructor) }
      let(:course_owner_transferor) do
        described_class.new(course, owner, destination_instructor)
      end

      it 'does not transfer the course' do
        course_owner_transferor.transfer
        course.reload
        expect(course.owner).to eq owner
      end

      it 'returns false' do
        expect(course_owner_transferor.transfer).to be false
      end

      it 'logs an error of why the course could not be transferred' do
        course_owner_transferor.transfer
        expect(course_owner_transferor.errors).to include 'Only an institution admin can transfer courses.'
      end
    end

    context 'when the user doing the transfer is the owner of the course' do
      let(:course_owner_transferor)  do
        described_class.new(course, owner, destination_instructor)
      end
      let!(:section) { create(:section, course: course, instructor: owner) }

      it 'returns true' do
        expect(course_owner_transferor.transfer).to be true
      end

      it 'transfers the course' do
        course_owner_transferor.transfer
        course.reload
        expect(course.owner).to eq destination_instructor
      end

      it 'transfers the sections' do
        course_owner_transferor.transfer
        section.reload
        expect(section.instructor).to eq destination_instructor
      end

      it 'transfers the section_instructor record' do
        course_owner_transferor.transfer
        section.reload
        section.section_instructors.each do |section_instructor|
          expect(section_instructor.instructor).to eq destination_instructor
        end
      end

      it 'transfers the forums' do
        forum = create(:forum, section: section, instructor: owner)
        course_owner_transferor.transfer
        forum.reload
        expect(forum.instructor).to eq destination_instructor
      end

      context 'with errors' do
        it 'logs the error if there were issues updating the course' do
          allow(course).to receive(:name).and_return(nil)
          course_owner_transferor.transfer
          expect(course_owner_transferor.errors).to eq ['Name is required']
        end

        it 'logs the error if there was issues updating the course' do
          allow(course).to receive(:sections).and_return([section])
          allow(section).to receive(:hide_owner_name).and_return(true)
          course_owner_transferor.transfer
          expect(course_owner_transferor.errors).to eq ['Additional instructors To ' \
                                                        'hide section owner name, at least' \
                                                        ' a Co-Instructor or Assistant is required']
        end
      end
    end
  end
end
