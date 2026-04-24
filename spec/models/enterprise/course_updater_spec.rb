RSpec.describe Enterprise::CourseUpdater do
  subject(:course_updater) { described_class.new(course, update_params) }

  let(:course_owner_updater) { instance_double(Enterprise::CourseOwnerUpdater) }
  let(:program) { create(:program) }
  let(:instructor) { create(:instructor) }
  let(:course) do
    create(
      :enterprise_course,
      program:,
      owner: instructor,
      enterprise_section: create(:enterprise_section, class_days: '2, 4', instructor:)
    )
  end

  let(:update_params) { { name: 'Updated Course Name' } }

  describe '#update' do
    before do
      allow(course_updater).to receive(:course_owner_updater).and_return(course_owner_updater)
    end

    context 'when the course is not enterprise' do
      let(:course_result) { course_updater.update }

      before do
        allow(course).to receive(:is_enterprise?).and_return(false)
      end

      it { expect(course_result).to eq(course) }
      it { expect(course_result.errors[:base]).to include('Course must be enterprise') }
    end

    context 'when the course owner updater is not valid' do
      let(:course_result) { course_updater.update }

      before do
        allow(course_owner_updater).to receive(:to_update?).and_return(true)
        allow(course_owner_updater).to receive(:valid?).and_return(false)
        allow(course_owner_updater).to receive(:errors).and_return(['Fake error'])
      end

      it { expect(course_result).to eq(course) }
      it { expect(course_result.errors[:base]).to include('Fake error') }
    end

    context 'when the course is valid to be updated' do
      before do
        allow(course_owner_updater).to receive(:to_update?).and_return(true)
        allow(course_owner_updater).to receive(:valid?).and_return(true)
        allow(course_owner_updater).to receive(:update)
      end

      it 'updates the course owner' do
        course_updater.update

        expect(course_owner_updater).to have_received(:update)
      end

      context 'when class_days are updated' do
        let(:new_class_days) { '1, 3, 5' }
        let!(:section) do
          create(:section, course:, instructor:, class_days: course.enterprise_section.class_days)
        end
        let(:enterprise_section_attributes) do
          { id: course.enterprise_section.id, class_days: new_class_days }
        end

        before do
          update_params[:enterprise_section_attributes] = enterprise_section_attributes
          course.reload
          course_updater.update
        end

        it { expect(course.reload.enterprise_section.class_days).to eq(new_class_days) }
        it { expect(section.reload.class_days).to eq(new_class_days) }
      end

      context 'when an error occurs during the transaction' do
        before do
          allow(course_owner_updater).to receive(:update).and_raise(ActiveRecord::RecordInvalid)
        end

        it 'propagates the error' do
          expect { course_updater.update }.to raise_error(ActiveRecord::RecordInvalid)
        end

        it 'does not update the course' do
          original_attributes = course.attributes

          begin
            course_updater.update
          rescue ActiveRecord::RecordInvalid
            course.reload
          end

          expect(course.attributes).to eq(original_attributes)
        end
      end
    end
  end
end
