require 'rails_helper'

describe ActivityStandardHashable do
  let(:dummy_class) { Class.new { include ActivityStandardHashable } }
  let(:dummy_instance) { dummy_class.new }
  let(:activity) { create(:activity) }
  let(:standards_program) { create(:program) }
  let(:instructor) { create(:instructor) }
  let(:standard_set) { create(:standard_set) }
  let!(:program_config) do
    create(
      :program_config_with_standard_sets,
      program: standards_program,
      supported_standard_sets: [standard_set]
    )
  end
  let(:standards_course) do
    create(
      :open_course,
      owner: instructor,
      program: standards_program,
      standard_set_ids: [standard_set.id]
    )
  end
  let(:standards_section) do
    create(
      :section,
      course: standards_course,
      instructor:
    )
  end
  let(:assignment) { create(:assignment, section: standards_section) }
  let(:standard_asset) { create(:standard_asset, reference_id: activity.cms_activity_id) }
  let(:standard) do
    create(:standard, vendor_standard_set_guid: standard_set.vendor_guid)
  end
  let(:alignment) do
    double('Alignment',
           standard_asset_id: standard_asset.id,
           vendor_standard_set_guid: standard.vendor_standard_set_guid,
           vendor_guid: standard.vendor_guid,
           display_name: standard.standard_set.display_name)
  end

  let!(:standard_alignment) do
    create(
      :standard_alignment,
      standard_asset:,
      vendor_standard_guid: standard.vendor_guid
    )
  end

  before do
    allow(dummy_instance).to receive(:activity_assignments).and_return([assignment])
    allow(dummy_instance).to receive(:availability_status).and_return('available')
    allow(dummy_instance).to receive(:toc_format_due_date).and_return({})
    allow(dummy_instance).to receive(:release_link_text).and_return('Release Link Text')
    allow(dummy_instance).to receive(:assessment_release_link_hover_text).and_return('Hover Text')
    allow(dummy_instance).to receive(:unassigned_sections).and_return([])
    allow(dummy_instance).to receive(:assigned_on_multiple_dates?).and_return(false)
    allow(dummy_instance).to receive(:format_activity_icons).and_return('formatted_icon')
    allow(dummy_instance).to receive(:format_alignments).and_return('formatted_alignments')
    allow(dummy_instance).to receive(:activity_url).and_return('activity_url')
    allow(dummy_instance).to receive(:vista_online_learning?).and_return(false)
  end

  describe '#item' do
    it 'returns a formatted hash' do
      expected_hash = {
        activityId: activity.id,
        activityTitle: activity.title,
        assigned: nil,
        assessmentAvailability: 'available',
        assignmentsDueDate: {},
        assignmentIds: assignment.id.to_s,
        referenceType: 'AssessmentItem',
        releaseLinkText: 'Release Link Text',
        activityUrl: 'activity_url',
        activityIcons: 'formatted_icon',
        te_descriptor: nil,
        unassignableReason: nil,
        hoverText: 'Hover Text',
        isAssignable: true,
        isExam: false,
        isIndividuallyAssigned: false,
        pageNumber: nil,
        pageSection: nil,
        unitId: activity.lesson.unit.id,
        lessonId: activity.lesson_id,
        showReleaseLink: false,
        standardAlignments: 'formatted_alignments',
        strand_color: activity.concept.background_color
      }
      expect(
        dummy_instance.item(activity, 'AssessmentItem', [alignment])
      ).to eq(expected_hash)
    end
  end

  describe '#grouped_alignments' do
    it 'groups alignments by standard_asset_id' do
      expected_result = {
        standard_asset.id.to_s => [{
          standardSetGuid: standard.vendor_standard_set_guid,
          standardGuid: standard.vendor_guid,
          standardSetDisplayName: standard.standard_set.display_name
        }]
      }
      expect(dummy_instance.grouped_alignments([alignment])).to eq(expected_result)
    end
  end

  describe '#fetch_alignments' do
    it 'fetches alignments based on standard_asset_ids and course_standard_set_guids' do
      allow(StandardAlignment).to receive_message_chain(
        :where, :joins, :where, :select
      ).and_return([standard_alignment])
      result = dummy_instance.fetch_alignments([standard_asset.id], [standard_set.vendor_guid])
      expect(result).to eq([standard_alignment])
    end
  end

  describe '#alignments_hash' do
    it 'returns a hash with default value as an empty array' do
      hash = dummy_instance.alignments_hash
      expect(hash).to be_a(Hash)
      expect(hash[:non_existent_key]).to eq([])
    end
  end
end
