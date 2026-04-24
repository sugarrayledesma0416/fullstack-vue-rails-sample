import { omit, reject } from 'shared/utils';

/**
 * Class representing serializer for Section.
 */
class SectionSerializer {
  /**
   * Instantiate the SectionSerializer class.
   */
  constructor() { }

  /**
   * Format class days of a section
   * @param {Object} section - Object of section mode.
   * @return {String} classDays - Formatted value of class days of a section.
   */
  prepClassDays(section) {
    const classDays = [];
    for (const index in section.classDays) {
      if (section.classDays[index]) {
        classDays.push(index);
      }
    }

    return classDays.join(',');
  }

  /**
   * Get Section Instructor Attributes.
   * @param {Object} section - Object of section mode.
   * @return {Object} instructorAttrs - section instructor attributes.
   */
  sectionInstructorAttrs(section) {
    let instructorAttrs = section.sectionInstructors.map(function(si) {
      return omit(['full_name', 'first_name', 'last_name'], si);
    });

    // if editing an existing section, set any section instructors with blank role to be destroyed
    if (section.id) {
      instructorAttrs = instructorAttrs.map(function(si) {
        if (si.role === '') {
          si['_destroy'] = true;
        }
        return si;
      });
    } else {
      instructorAttrs = reject(instructorAttrs, function(si) {
        return si.role === '';
      });
    }
    return instructorAttrs;
  }

  /**
   * Serialize section model.
   * @param {Object} section - Object of section mode.
   * @return {Object} - serialized object of section.
   */
  serialize(section) {
    return {
      section: {
        name: section.name || '',
        class_days: this.prepClassDays(section),
        assignment_copy_section_id: section.assignmentCopySectionId,
        additional_info: section.additionalInfo,
        section_instructors_attributes: this.sectionInstructorAttrs(section),
        due_time: section.dueTimeHour + ':' + section.dueTimeMinute + section.dueTimeAmpm,
        time_zone: section.timeZone,
        instructor_id: section.instructor.id,
        hide_owner_name: section.hideOwnerName,
        open_to_students: section.openToStudents,
        days_to_show_assignment_due_date: section.daysToShowAssignmentDueDate,
        copy_external_assignments: section.copyExternalAssignments,
      },
    };
  }
}

export default SectionSerializer;
