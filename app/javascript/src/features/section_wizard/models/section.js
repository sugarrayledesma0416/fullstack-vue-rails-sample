import * as ajaxUtils from 'shared/ajax_utils';
import SectionHttp from './../services/section_http';
import SectionSerializer from './../services/section_serializer';
import { compose, isEmpty, isObjEmpty, reject, sort } from 'shared/utils';

/**
 * Defines the creation of section object based on the data passed.
 * @param {Object} sectionData - section data.
 * @return {Object} newSection - Section Object.
 */
const createSection = function(sectionData) {
  const newSection = new Section();
  newSection.init(sectionData);
  return newSection;
};

/**
 * Class representing Section.
 */
class Section {
  /**
   * Instantiate the Section class.
   */
  constructor() {
    this.hourOptions = ['12', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'];
    this.minutesOptions = ['00', '15', '30', '45', '59'];
    this.ampmOptions = ['AM', 'PM'];
    this.possibleClassDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    this.sortedInstructorNames = compose(
      this.formattedFullNames,
      this.descendingByRole,
      this.sectionInstructorsWithRoles
    );
    this.sortedNonOwnerNames = compose(this.sortedInstructorNames, this.nonOwners);
    this.saving = false;
  }

  /**
   * Whether any instructor is Co-Instructor or Assistant.
   * @return {boolean}
   */
  get anyCoInstructorOrAssistant() {
    return this.sectionInstructors.some((instructor) => {
      return ['Co-instructor', 'Assistant'].includes(instructor.role);
    });
  }

  /**
   * Get assignment availability message.
   * @return {string}
   */
  get assignmentAvailabilityMessage() {
    if (this.daysToShowAssignmentDueDate) {
      return `Available to students ${this.daysToShowAssignmentDueDate} days before due date`;
    }
    return 'All upcoming assignments available to students.';
  }

  /**
   * Get Available options
   * @return {Object} options
   */
  get availableOptions() {
    const options = {
      'Frequently Used': [
        { text: 'Always', value: null, group: 'Frequently Used' },
        { text: '1 Week', value: 7, group: 'Frequently Used' },
        { text: '2 Weeks', value: 14, group: 'Frequently Used' },
      ],
      'Other': [],
    };
    options['Other'].push({ text: '1 day', value: 1, group: 'Other' });
    for (let i = 2; i < 31; i++) {
      options['Other'].push({ text: `${i} days`, value: i, group: 'Other' });
    }
    return options;
  }

  /**
   * Get course id
   * @return {number}
   */
  get courseId() {
    return this.course && this.course.id;
  }

  /**
   * Get all sections corresponding to a course.
   * @return {Object} sectionItems
   */
  get courseSections() {
    const courseId = this.courseId;
    const previousSections = this.previousSections || null;
    const sectionItems = [];
    if (courseId && previousSections) {
      previousSections.forEach(function(previousSection) {
        if (
          courseId === previousSection.course.id &&
          previousSection.assignmentsPresent ||
          previousSection.hasExternalAssignments
        ) {
          sectionItems.push({
            id: previousSection.id,
            name: previousSection.name,
            assignmentPastDueCount: previousSection.assignmentPastDueCount,
          });
        }
      });
    }
    return sectionItems;
  }

  /**
   * Get if the couse contains any pre-existing sections
   * @return {boolean}
   */
  get courseSectionsPresent() {
    return this.courseSections.length > 0;
  }

  /**
   * Get last names of the section instructors
   * @return {Object} - List of last names of the section instructors.
   */
  get instructorLastNames() {
    if (this.hideOwnerName) {
      return this.sortedNonOwnerNames(this.sectionInstructors);
    } else {
      return this.sortedInstructorNames(this.sectionInstructors);
    }
  }

  /**
   * Check whether assignment can be copied from existing section.
   * @return {boolean} - whether assignment can be copy.
   */
  get canCopyAssignments() {
    return this.courseSectionsPresent && !this.assignmentsPresent;
  }

  /**
   * checks for the type of error and returns it's corresponding message
   * @return {Object} - object that contains its value and error message.
   */
  get hasError() {
    if (this.name === '' && this.isValidatorEnabled) {
      return {
        id: 'empty_section_name',
        value: true,
        msg: 'Section name is required.',
      };
    } else if (this.name?.length > 75 && this.isValidatorEnabled && !this.ltiRosterLinked) {
      return {
        id: 'invalid_section_name',
        value: true,
        msg: 'Your section name cannot be longer than 75 characters.',
      };
    } else {
      return {
        value: false,
        msg: '',
      };
    }
  }

  /**
   * It returns whether the name is readonly or not.
   * @return {boolean}
   */
  get isNameReadonly() {
    return this.oneRosterLinked;
  }

  /**
   * It returns whether the name is valid or not.
   * @return {boolean}
   */
  get isNameValid() {
    return this.isNameReadonly ? true : !isEmpty(this.name) &&
           (this.name.length <= 75 || this.ltiRosterLinked);
  }

  /**
   * The name must be a non-empty string 75 characters or shorter &
   * additional instructor setup should be valid.
   * @return {boolean}
   */
  get isValid() {
    return this.isNameValid && this.isAdditionalInstructorSetupValid;
  }

  /**
   * @private
   * Check Whether additional instructor setup is valid.
   * @return {boolean}
   */
  get isAdditionalInstructorSetupValid() {
    return (
      !this.hideOwnerName ||
      (this.hideOwnerName && this.anyCoInstructorOrAssistant)
    );
  }


  /**
   * Sort Instructor by roles.
   * @param {Array} instructors - Arrays of Instructors of the section.
   * @return {Array}
   */
  descendingByRole(instructors) {
    return sort(instructors, 'role', 'desc');
  }

  /**
   * Format Full names of the Instructors.
   * @param {Object} instructors - Arrays of Instructors of the section.
   * @return {Object}
   */
  formattedFullNames(instructors) {
    return instructors.map(function(instructor) {
      return `${instructor.last_name}, ${instructor.first_name}`;
    });
  }

  /**
   * Init section.
   * @param {Object} params - params to define section model.
   */
  init(params) {
    if (params.id) {
      this.id = params.id;
    }
    this.initDueTime(params);
    this.initSectionInstructors(params);
    this.initPreviousSectionDetails(params);
    this.course = params.course;
    this.name = params.name;
    this.additionalInfo = params.additional_info;
    this.timeZone = params.time_zone;
    this.assignmentCopySectionId = '';
    this.copyExternalAssignments;
    this.classDays = params.class_days;
    this.hideOwnerName = params.hide_owner_name;
    this.openToStudents = params.open_to_students;
    this.allowEnrollmentLock = params.allow_enrollment_lock;
    this.assignmentPastDueCount = params.assignment_past_due_count;
    this.assignmentsPresent = params.assignments_present;
    this.daysToShowAssignmentDueDate = params.days_to_show_assignment_due_date;
    this.showPreview = false;
    this.showModal = false;
    this.oneRosterLinked = params.one_roster_linked;
    this.ltiRosterLinked = params.lti_roster_linked;
    this.autorosteringLinked = params.autorostering_linked;
    /**
     *  This property is relevant only for the section being created or updated.
     *  Its value after initialization is determined when the user selects (or deselects)
     *  a previous section from which to copy assignments.
     */
    this.copySectionHasExternalAssignments = false;

    /**
     * This property is relevant only for a section that is part of the previous-sections
     * collection in the section being created or updated. When the user selects a section
     * in that collection as the source for the assignment copy, its value for this property
     * is assigned to the copySectionHasExternalAssignments property of the
     * section being created or updated.
     */
    this.hasExternalAssignments = params.has_external_assignments;
    this.isValidatorEnabled = false;
  }

  /**
   * Filter Instructor that are not owners.
   * @param {Array} instructors - Arrays of Instructors of the section.
   * @return {Array}
   */
  nonOwners(instructors) {
    return reject(instructors, function(instructor) {
      return instructor.role === 'Instructor';
    });
  }

  /**
   * Saves the section data to the database.
   * @return {Object}
   */
  save() {
    this.saving = true;
    const url = `/instructor/${this.course.program_id}/courses/${this.course.id}/sections.json`;
    const sectionSerializer = new SectionSerializer();
    return ajaxUtils.postToEndpoint(
      url,
      sectionSerializer.serialize(this),
      (response) => {
        if (response.redirect_to) {
          try {
            const sectionDispatcher = new VHL.CarlinDispatch.Logstash('new_section');
            sectionDispatcher.dispatch('section');
          } catch (e) {
            console.log('there was an error sending stats', e);
          }

          const sectionHttp = new SectionHttp();
          sectionHttp.returnToDashboard();
        } else {
          console.log(response);
          this.saving = false;
        }
      }
    );
  }

  /**
   * Filter Instructor with roles.
   * @param {Array} instructors - Arrays of Instructors of the section.
   * @return {Array}
   */
  sectionInstructorsWithRoles(instructors) {
    return reject(instructors, function(instructor) {
      return isObjEmpty(instructor.role);
    });
  }

  /**
   * Updates section data to the database.
   * @param {FlashMessageState} flashMessageState - Wrapper on vue js reactive object
   * to store flash message state for section wizard.
   * @return {Object}
   */
  update(flashMessageState) {
    this.saving = true;
    const url = `/instructor/${this.course.program_id}/courses/${this.course.id}/` +
      `sections/${this.id}.json`;
    const sectionSerializer = new SectionSerializer();
    return ajaxUtils.putToEndpoint(
      url,
      sectionSerializer.serialize(this),
      (data) => {
        if (data.id) {
          this.sectionInstructors = data.section_instructors;
          flashMessageState.displayNotice();
          document.dispatchEvent(new CustomEvent('section_update_saved'));
          const sectionHttp = new SectionHttp();
          sectionHttp.returnToDashboard();
        } else {
          this.saving = false;
          flashMessageState.displayError();
        }
      }
    );
  }

  /**
   * @private
   * Init section due time details.
   * @param {Object} params - params to define section model.
   */
  initDueTime(params) {
    this.dueTimeHour = params.due_time_hour;
    this.dueTimeMinute = params.due_time_min;
    this.dueTimeAmpm = params.due_time_ampm;
  }

  /**
   * @private
   * Init Previous section details.
   * @param {Object} params - params to define section model.
   */
  initPreviousSectionDetails(params) {
    this.previousClassdaysSectionId = null;
    this.previousSections = params.previous_sections ?
      params.previous_sections.map(createSection) :
      [];
  }

  /**
   * @private
   * Init section instructors details.
   * @param {Object} params - params to define section model.
   */
  initSectionInstructors(params) {
    this.instructor = params.instructor;
    this.sectionInstructors = params.section_instructors;
    this.instructorCreatorRoles = params.instructor_creator_roles;
    this.instructorRoles = params.instructor_roles;
  }
}

export { Section, createSection };
