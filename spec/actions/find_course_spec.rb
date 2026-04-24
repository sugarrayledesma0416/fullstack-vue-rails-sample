require 'rails_helper'
require 'light-service/testing'

RSpec.describe FindCourse do
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

  context 'when the course exists' do
    it 'is successful' do
      result = described_class.execute(context)
      expect(result).to be_success
    end
  end

  context 'when the course does not exist' do
    let(:course) { OpenStruct.new(id: 1 ) }
    let(:result) { described_class.execute(context) }

    it 'fails the context' do
      expect(result).to be_failure
    end

    it 'returns a message' do
      expect(result.message).to eq('Unable to find course.')
    end
  end

  context 'when a course_scope exists on the context' do
    let(:context) do
      LightService::Testing::ContextFactory
        .make_from(AssignmentWizardCopier)
        .for(described_class)
        .with(params, :enterprise)
    end

    it 'applies the appropriate scope to the query' do
      expect(Course).to receive(:enterprise).and_return(Course.none)
      described_class.execute(context)
    end

    context 'when the course_scope is not expected' do
      let(:context) do
        LightService::Testing::ContextFactory
          .make_from(AssignmentWizardCopier)
          .for(described_class)
          .with(params, :unexpected_scope)
      end

      it 'does not apply the given scope' do
        expect(Course).not_to receive(:unexpected_scope)
        described_class.execute(context)
      end
    end
  end
end
