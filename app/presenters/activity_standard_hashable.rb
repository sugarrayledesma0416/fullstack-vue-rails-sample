module ActivityStandardHashable
  attr_writer :assignment_validator, :vtext_linker

  include TimeHandler
  include ActivityIconsFormatter
  include AssessmentAvailabilityChecker
  include DateTimeHelper
  include UnassignedSectionsLookup
  include MultipleDueDatesChecker

  # rubocop:disable Metrics/MethodLength
  def item(activity, type, alignments)
    page_number = activity.page_number if defined?(activity.page_number)
    page_section = activity.page_section if defined?(activity.page_section)
    te_descriptor = activity.descriptor if type == 'EReaderItem'
    {
      activityId: activity.id,
      activityTitle: activity.title,
      assessmentAvailability: availability_status(activity.id, :show_at),
      assigned: activity.instance_eval { @assigned },
      assignmentsDueDate: toc_format_due_date(activity.id),
      assignmentIds: activity_assignments(activity.id).pluck(:id).join('-'),
      referenceType: type,
      releaseLinkText: release_link_text(activity.id, 'assessment_release'),
      activityUrl: activity_url(activity, type),
      activityIcons: format_activity_icons(
        activity[:icon],
        vista_online_learning?,
        activity.instructor_graded?
      ),
      te_descriptor:,
      hoverText: assessment_release_link_hover_text(activity.id),
      isExam: activity.assessment?,
      isIndividuallyAssigned: activity_assignments(activity.id).any?(&:individually_assignable),
      pageNumber: page_number.presence,
      pageSection: page_section.presence,
      unitId: activity.lesson.unit.id,
      lessonId: activity.lesson_id,
      showReleaseLink: activity_assignments(activity.id).any? do |assignment|
        assignment.show_assessment == 'I release it'
      end,
      standardAlignments: format_alignments(alignments),
      strand_color: activity.concept.background_color
    }.tap do |memo|
      memo[:unassignableReason] = @assignment_validator&.unassignable_reason(activity)
      memo[:isAssignable] = memo[:unassignableReason].blank?
    end
  end
  # rubocop:enable Metrics/MethodLength

  def grouped_alignments(alignments)
    alignments.each_with_object(alignments_hash) do |aln, a_h|
      a_h[aln.standard_asset_id.to_s] << {
        standardSetGuid: aln.vendor_standard_set_guid,
        standardGuid: aln.vendor_guid,
        standardSetDisplayName: aln.display_name
      }
    end
  end

  def fetch_alignments(standard_asset_ids, course_standard_set_guids)
    StandardAlignment
      .where(standard_asset_id: standard_asset_ids)
      .joins(standard: :standard_set)
      .where(standards: { vendor_standard_set_guid: course_standard_set_guids })
      .select(:standard_asset_id, 'standards.vendor_guid', :vendor_standard_set_guid, :display_name)
  end

  def alignments_hash
    Hash.new { |hash, key| hash[key] = [] }
  end

  private def cms_activity_id(item)
    # TE items dont have cms_activity_id so we need to ignore them
    return if item[:reference_type] == 'EReaderItem'

    # Returns the cms_activity_id of the result item
    if item[:reference_type] == 'AssessmentItem'
      AssessmentItem.find(item[:reference_id]).assessment_id
    else
      item[:reference_id]
    end
  end

  private def te_item_id(item)
    return if item[:reference_type] != 'EReaderItem'

    item[:reference_id]
  end

  private def activity_assignments(activity_id)
    @assignments_by_activity[activity_id] || []
  end
  alias assignments_for_activity activity_assignments

  private def toc_format_due_date(activity_id)
    assignments = activity_assignments(activity_id)
    return nil if assignments.empty?

    if !assigned_on_multiple_dates?(assignments) && unassigned_sections(activity_id).blank?
      format_date_time(assignments.first.due_date, :today_or_date)
    else
      'Date Varies'
    end
  end

  private def activity_url(activity, type)
    if type == 'EReaderItem'
      "#{@vtext_linker&.link}?rid=0&page=#{activity.page_number}"
    else
      section_activity_path(id: activity.id, section_id: 0)
    end
  end

  private def format_alignments(alignments)
    display_names = alignments.pluck(:standardSetDisplayName).uniq
    display_names.index_with do |name|
      alignments.select { |aln| name == aln[:standardSetDisplayName] }
    end
  end

  private def vista_online_learning?
    raise NotImplementedError
  end
end
