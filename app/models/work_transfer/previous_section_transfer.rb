module WorkTransfer
  class PreviousSectionTransfer < ::StudentWorkTransfer
    # We overwrite this method because we want to be able to transfer work to previous sections.
    def unblock_access!
    end

    def valid_enrollment?
      @student.enrollments.by_section(@section_to).present?
    end
  end
end
