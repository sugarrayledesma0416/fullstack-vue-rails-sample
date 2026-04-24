require 'rails_helper'

RSpec.describe AssignmentWizardCopier do
  let(:course) { create(:course) }
  let(:params) do
    ActionController::Parameters.new(
      {
        course_id: course.id,
        section_id: 0,
        source_section_id: 0,
        raw_assignments: {},
        categories: {},
        copy_external_items?: true
      }
    )
  end

  it 'sets categories_hash as a Hash on the context' do
    expect(described_class.call(params).categories_hash).to be_a(Hash)
  end

  it 'sets assignments_hash as a Hash on the context' do
    expect(described_class.call(params).assignments_hash).to be_a(Hash)
  end

  it 'sets section_id on the context' do
    expect(described_class.call(params).destination_section_id).not_to be_nil
  end

  it 'sets course_id on the context' do
    expect(described_class.call(params).course_id).not_to be_nil
  end

  it 'sets source_section_id on the context' do
    expect(described_class.call(params).source_section_id).not_to be_nil
  end

  it 'sets 2 job_ids on the context' do
    expect(described_class.call(params).job_ids.count).to eq 2
  end

  context 'when copy_external_items? flag is false' do
    let(:params) do
      ActionController::Parameters.new(
        {
          course_id: course.id,
          section_id: 0,
          source_section_id: 0,
          raw_assignments: {},
          categories: {},
          copy_external_items?: false
        }
      )
    end

    it 'does not call ScheduleExternalItemCopy' do
      expect(ScheduleExternalItemCopy).not_to receive(:call)

    end
  end

  context 'when source_section_id is provided' do
    let(:params) do
      ActionController::Parameters.new(
        {
          course_id: course.id,
          section_id: 0,
          source_section_id: nil,
          raw_assignments: {},
          categories: {}
        }
      )
    end

    it 'does not call ScheduleExternalItemCopy' do
      expect(ScheduleExternalItemCopy).not_to receive(:call)
    end
  end

  it 'enqueues the creation job' do
    expect do
      described_class.call(params)
    end.to change(CopyExternalItemsWorker.jobs, :size).by(1)
  end

  it 'adds the job id to the context' do
    expect(described_class.call(params).job_ids).not_to be_empty
  end
end
