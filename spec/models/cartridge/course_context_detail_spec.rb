require 'rails_helper'

RSpec.describe Cartridge::CourseContextDetail, type: :model do
  context 'when model is created by factory girl' do
    let(:cartridge_course_context_detail) { FactoryBot.create(:cartridge_course_context_detail) }

    it 'is valid' do
      expect(cartridge_course_context_detail).to be_valid
    end
  end

  describe '.validations' do
    it { is_expected.to validate_presence_of(:lms_context_id) }
    it { is_expected.not_to validate_presence_of(:lis_outcome_service_url) }
  end

  describe 'ActiveRecord associations' do
    it { is_expected.to belong_to(:section) }
    it { is_expected.to belong_to(:school) }
    it { is_expected.to belong_to(:course) }
  end

  describe 'default_scope' do
    it 'excludes archive course_context_detail records' do
      course_context_detail = create(:cartridge_course_context_detail, is_archived: true)

      expect { described_class.find(course_context_detail.id) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#update_lis_outcome_service_url' do
    it 'update the course contex detail with the new url' do
      new_url = 'www.newurl.com'
      existing_course_contex_detail = create(
        :cartridge_course_context_detail,
        lis_outcome_service_url: nil
      )

      expect do
        existing_course_contex_detail.update_lis_outcome_service_url(new_url)
      end.to change(described_class, :count).by(0)
      expect(existing_course_contex_detail.reload).to have_attributes(
        lis_outcome_service_url: new_url
      )
    end
  end
end
