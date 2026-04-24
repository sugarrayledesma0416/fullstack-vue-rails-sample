# rubocop:disable Metrics/AbcSize, Metrics/MethodLength
module StandardsAssigningHelpers
  def assets_and_standards_payload
    {
      aligned_items: aligned_items_result.to_json,
      standards_info: aligned_standards_result.to_json,
      next_key: { standard_asset_id: standard_asset_4.id }.to_json
    }
  end

  private def aligned_items_result
    {
      activity_1.lesson.unit.id => {
        activity_1.lesson.id => {
          activity_1.concept.id => [
            {
              activityId: activity_1.id,
              activityTitle: activity_1.title,
              assessmentAvailability: '',
              assigned: nil,
              assignmentsDueDate: nil,
              assignmentIds: '',
              referenceType: 'Activity',
              releaseLinkText: 'Release',
              activityUrl: "/sections/0/activities/#{activity_1.id}",
              activityIcons: %w[microphone],
              te_descriptor: nil,
              hoverText: '',
              isAssignable: true,
              isExam: activity_1.assessment?,
              isIndividuallyAssigned: false,
              unitId: activity_1.lesson.unit.id,
              lessonId: activity_1.lesson_id,
              pageNumber: nil,
              pageSection: nil,
              showReleaseLink: false,
              standardAlignments: {
                standard_set_1.display_name => [
                  {
                    standardSetGuid: standard_set_1.vendor_guid,
                    standardSetDisplayName: standard_set_1.display_name,
                    standardGuid: standard_1.vendor_guid
                  }
                ]
              },
              standardAssetIds: [standard_asset_1.id],
              strand_color: activity_1.concept.background_color,
              unassignableReason: nil
            }
          ]
        }
      },
      activity_2.lesson.unit.id => {
        activity_2.lesson.id => {
          activity_2.concept.id => [
            {
              activityId: activity_2.id,
              activityTitle: activity_2.title,
              assessmentAvailability: '',
              assigned: nil,
              assignmentsDueDate: nil,
              assignmentIds: '',
              referenceType: 'Activity',
              releaseLinkText: 'Release',
              activityUrl: "/sections/0/activities/#{activity_2.id}",
              activityIcons: %w[microphone apple],
              te_descriptor: nil,
              hoverText: '',
              isAssignable: true,
              isExam: activity_2.assessment?,
              isIndividuallyAssigned: false,
              unitId: activity_2.lesson.unit.id,
              lessonId: activity_2.lesson_id,
              pageNumber: nil,
              pageSection: nil,
              showReleaseLink: false,
              standardAlignments: {
                standard_set_2.display_name => [
                  {
                    standardSetGuid: standard_set_2.vendor_guid,
                    standardSetDisplayName: standard_set_2.display_name,
                    standardGuid: standard_2.vendor_guid
                  }
                ]
              },
              standardAssetIds: [standard_asset_2.id],
              strand_color: activity_2.concept.background_color,
              unassignableReason: nil
            }
          ]
        },
        standard_asset_3.assessment_item.assessment.lesson.id.to_s =>
        {
          standard_asset_3.assessment_item.assessment.concept.id.to_s =>
          [
            {
              activityId: standard_asset_3.assessment_item.assessment.id,
              activityTitle: standard_asset_3.assessment_item.assessment.title,
              assessmentAvailability: '',
              assigned: nil,
              assignmentsDueDate: nil,
              assignmentIds: '',
              referenceType: 'AssessmentItem',
              releaseLinkText: 'Release',
              activityUrl: "/sections/0/activities/#{standard_asset_3.assessment_item.assessment.id}",
              activityIcons: %w[],
              te_descriptor: nil,
              hoverText: '',
              isAssignable: true,
              isExam: true,
              isIndividuallyAssigned: false,
              unitId: standard_asset_3.assessment_item.assessment.lesson.unit.id,
              lessonId: standard_asset_3.assessment_item.assessment.lesson.id,
              pageNumber: nil,
              pageSection: nil,
              showReleaseLink: false,
              standardAlignments: {
                standard_set_2.display_name => [
                  {
                    standardSetGuid: standard_2.vendor_standard_set_guid,
                    standardSetDisplayName: standard_set_2.display_name,
                    standardGuid: standard_alignment_3.vendor_standard_guid
                  }
                ]
              },
              standardAssetIds: [standard_asset_3.id],
              strand_color: activity_2.concept.background_color,
              unassignableReason: nil
            },
            {
              activityId: standard_asset_4.ereader_item.id,
              activityTitle: standard_asset_4.ereader_item.title,
              assessmentAvailability: '',
              assigned: nil,
              assignmentsDueDate: nil,
              assignmentIds: '',
              referenceType: 'EReaderItem',
              releaseLinkText: 'Release',
              activityUrl: "?rid=0&page=#{standard_asset_4.ereader_item.page_number}",
              activityIcons: %w[],
              te_descriptor: standard_asset_4.ereader_item.descriptor,
              hoverText: '',
              isAssignable: true,
              isExam: false,
              isIndividuallyAssigned: false,
              unitId: standard_asset_4.ereader_item.concept.lesson.unit.id,
              lessonId: standard_asset_4.ereader_item.concept.lesson.id,
              pageNumber: standard_asset_4.ereader_item.page_number,
              pageSection: standard_asset_4.ereader_item.page_section,
              showReleaseLink: false,
              standardAlignments: {
                standard_set_2.display_name => [
                  {
                    standardSetGuid: standard_2.vendor_standard_set_guid,
                    standardSetDisplayName: standard_set_2.display_name,
                    standardGuid: standard_alignment_4.vendor_standard_guid
                  }
                ]
              },
              standardAssetIds: [standard_asset_4.id],
              strand_color: ereader_item.concept.background_color,
              unassignableReason: nil

            }
          ]
        }
      }
    }
  end

  private def aligned_standards_result
    {
      standards: {
        standard_2.vendor_guid => {
          vendor_guid: standard_2.vendor_guid,
          name: standard_2.name,
          description: standard_2.description,
          label: standard_2.label,
          number: standard_2.number,
          display_number: standard_2.number
        },
        standard_1.vendor_guid => {
          vendor_guid: standard_1.vendor_guid,
          name: standard_1.name,
          description: standard_1.description,
          label: standard_1.label,
          number: standard_1.number,
          display_number: standard_1.number
        }
      },
      standard_sets: {
        standard_set_2.vendor_guid => {
          vendor_guid: standard_set_2.vendor_guid,
          issuer: standard_set_2.issuer,
          name: standard_set_2.name,
          description: standard_set_2.description,
          display_name: standard_set_2.display_name
        },
        standard_set_1.vendor_guid => {
          vendor_guid: standard_set_1.vendor_guid,
          issuer: standard_set_1.issuer,
          name: standard_set_1.name,
          description: standard_set_1.description,
          display_name: standard_set_1.display_name
        }
      }
    }
  end

  def os_assets_result
    [
      {
        standard_asset_id: standard_asset_1.id,
        reference_type: 'Activity',
        reference_id: activity_1.cms_activity_id
      },
      {
        standard_asset_id: standard_asset_2.id,
        reference_type: 'Activity',
        reference_id: activity_2.cms_activity_id
      },
      {
        standard_asset_id: standard_asset_3.id,
        reference_type: 'AssessmentItem',
        reference_id: standard_asset_3.assessment_item.id
      },
      {
        standard_asset_id: standard_asset_4.id,
        reference_type: 'EReaderItem',
        reference_id: ereader_item.id
      },
      {
        standard_asset_id: standard_asset_4.id
      }
    ]
  end

  def os_asset_result_with_nil_toc_activity
    [
      {
        standard_asset_id: standard_asset_1.id,
        reference_type: 'Activity',
        reference_id: activity_1.cms_activity_id
      },
      {
        standard_asset_id: standard_asset_2.id,
        reference_type: 'Activity',
        reference_id: activity_2.cms_activity_id
      },
      {
        standard_asset_id: standard_asset_3.id,
        reference_type: 'AssessmentItem',
        reference_id: standard_asset_3.assessment_item.id
      },
      {
        standard_asset_id: standard_asset_nil_toc.id,
        reference_type: 'Activity',
        reference_id: activity_nil_toc.cms_activity_id
      },
      {
        standard_asset_id: standard_asset_4.id,
        reference_type: 'EReaderItem',
        reference_id: ereader_item.id
      },
      {
        standard_asset_id: standard_asset_4.id
      }
    ]
  end

  def os_assets_assessment_multiple_mappings
    [
      {
        standard_asset_id: standard_asset_for_ai_1.id,
        reference_type: 'AssessmentItem',
        reference_id: standard_asset_for_ai_1.assessment_item.id
      },
      {
        standard_asset_id: standard_asset_for_ai_2.id,
        reference_type: 'AssessmentItem',
        reference_id: standard_asset_for_ai_2.assessment_item.id
      },
      {
        standard_asset_id: standard_asset_for_ai_2a.id,
        reference_type: 'AssessmentItem',
        reference_id: standard_asset_for_ai_2a.assessment_item.id
      },
      {
        standard_asset_id: standard_asset_for_ai_2a_duplicate.id
      }
    ]
  end

  def assets_and_standards_payload_assessment_multiple_mappings
    {
      aligned_items: aligned_items_assessment_multiple_mappings.to_json,
      standards_info: aligned_standards_assessment_multiple_mappings.to_json,
      next_key: { standard_asset_id: standard_asset_for_ai_2a_duplicate.id }.to_json
    }
  end

  private def aligned_standards_assessment_multiple_mappings
    {
      standards: {
        standard_2.vendor_guid => {
          vendor_guid: standard_2.vendor_guid,
          name: standard_2.name,
          description: standard_2.description,
          label: standard_2.label,
          number: standard_2.number,
          display_number: standard_2.display_number
        },
        standard_2a.vendor_guid => {
          vendor_guid: standard_2a.vendor_guid,
          name: standard_2a.name,
          description: standard_2a.description,
          label: standard_2a.label,
          number: standard_2a.number,
          display_number: standard_2a.display_number
        },
        standard_1.vendor_guid => {
          vendor_guid: standard_1.vendor_guid,
          name: standard_1.name,
          description: standard_1.description,
          label: standard_1.label,
          number: standard_1.number,
          display_number: standard_1.display_number
        }
      },
      standard_sets: {
        standard_set_2.vendor_guid => {
          vendor_guid: standard_set_2.vendor_guid,
          issuer: standard_set_2.issuer,
          name: standard_set_2.name,
          display_name: standard_set_2.display_name,
          description: standard_set_2.description
        },
        standard_set_1.vendor_guid => {
          vendor_guid: standard_set_1.vendor_guid,
          issuer: standard_set_1.issuer,
          name: standard_set_1.name,
          display_name: standard_set_1.display_name,
          description: standard_set_1.description
        }
      }
    }
  end

  private def aligned_items_assessment_multiple_mappings
    {
      standard_asset_for_ai_1.assessment_item.assessment.lesson.unit.id.to_s =>
      {
        standard_asset_for_ai_1.assessment_item.assessment.lesson.id.to_s =>
        {
          standard_asset_for_ai_1.assessment_item.assessment.concept.id.to_s =>
          [
            {
              activityId: standard_asset_for_ai_1.assessment_item.assessment.id,
              activityTitle: standard_asset_for_ai_1.assessment_item.assessment.title,
              assessmentAvailability: '',
              assigned: nil,
              assignmentsDueDate: nil,
              assignmentIds: '',
              referenceType: 'AssessmentItem',
              releaseLinkText: 'Release',
              activityUrl: "/sections/0/activities/#{standard_asset_for_ai_1.assessment_item.assessment.id}",
              activityIcons: %w[],
              te_descriptor: nil,
              hoverText: '',
              isAssignable: true,
              isExam: true,
              isIndividuallyAssigned: false,
              unitId: standard_asset_for_ai_1.assessment_item.assessment.lesson.unit.id,
              lessonId: standard_asset_for_ai_1.assessment_item.assessment.lesson.id,
              pageNumber: nil,
              pageSection: nil,
              showReleaseLink: false,
              standardAlignments: {
                standard_set_2.display_name => [
                  {
                    standardSetGuid: standard_2.vendor_standard_set_guid,
                    standardSetDisplayName: standard_set_2.display_name,
                    standardGuid: standard_2.vendor_guid
                  },
                  {
                    standardSetGuid: standard_2a.vendor_standard_set_guid,
                    standardSetDisplayName: standard_set_2.display_name,
                    standardGuid: standard_2a.vendor_guid
                  }
                ],
                standard_set_1.display_name => [
                  {
                    standardSetGuid: standard_1.vendor_standard_set_guid,
                    standardSetDisplayName: standard_set_1.display_name,
                    standardGuid: standard_1.vendor_guid
                  }
                ]
              },
              standardAssetIds: [
                standard_asset_for_ai_1.id,
                standard_asset_for_ai_2.id,
                standard_asset_for_ai_2a.id
              ],
              strand_color: standard_asset_for_ai_1.assessment_item.assessment.concept.background_color,
              unassignableReason: nil
            }
          ]
        }
      }
    }
  end
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength
