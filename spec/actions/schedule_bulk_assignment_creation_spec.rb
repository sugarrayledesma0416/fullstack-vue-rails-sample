require 'rails_helper'
require 'light-service/testing'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

RSpec.describe ScheduleBulkAssignmentCreation do
  let(:course) { create(:course) }
  let(:params) do
    ActionController::Parameters.new(
      {
        course_id: course.id,
        section_id: 0,
        source_section_id: 0,
        raw_assignments: {},
        categories: {}
      }
    )
  end

  let(:context) do
    LightService::Testing::ContextFactory
      .make_from(AssignmentWizardCopier)
      .for(described_class)
      .with(params)
  end

  it 'enqueues the creation job' do
    expect do
      described_class.execute(context)
    end.to change(BulkAssignmentWorker.jobs, :size).by(1)
  end

  it 'adds the job id to the context' do
    expect do
      described_class.execute(context)
    end.to change(context.job_ids, :size).by(1)
  end
end
