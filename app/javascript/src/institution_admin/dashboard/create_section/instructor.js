/**
 * @summary Model class for instructor subform.
 * This class maintains and validates the state of an individual
 * instructor subform in a section's collection of instructor
 * subform.
 */
class Instructor {
  /**
   * @summary Instantiate class and set initial state.
   * @param {Object} availableInstructors - all instructors available for selection
   */
  constructor(availableInstructors, instructor = {}) {
    this.availableInstructors = availableInstructors;

    /**
     * Initial state:
     * - no instructor selected
     * - no role selected
     * - do not show instructor in preview
     */
    this.selectedInstructorID = instructor.id || '';
    if (instructor.role) {
      this.selectedRole = this.roleOptions.find(option => option[0] == instructor.role)[1];
    } else {
      this.selectedRole = 0;
    }
    this.selectedRoleName = instructor.role || '';
    this.showInstructor = instructor.show || false;

    /** Array of values selected in other instructor subforms for this section.
     *    To be updated from outside when other instructor selections are
     *    changed.
     */
    this.allSelectedInstructors = [];
  }

  /**
   * @summary Change list of instructors selected in other subforms.
   * This method lets us keep the selected-instructors list current
   * so that we don't make an instructor selected elsewhere available
   * for selection in this subform.
   * @param {Array} values - array of selected instructor IDs
   */
  updateSelectedInstructors(values) {
    this.allSelectedInstructors = values;
  }

  /**
   * @summary Return whether subform is in a valid state.
   * The subform is valid if
   * - no instructor is selected, OR
   * - both an instructor and a role are selected
   * @returns {Boolean} true if subform is in valid state, false otherwise
   */
  valid() {
    /* It's OK for selection to be blank. */
    if (this.selectedInstructorID === '') {
      return true;
    }

    /* If an instructor is selected, role has to be selected also.
     *   Comparison is not strict because selectedRole may be a string.
     */
    return this.selectedRole != 0;
  }

  /**
   * @summary Return the options to be displayed in the select.
   * The select should have as options:
   * - the "blank" option, for no selection
   * - all available instructors that are _not_ currently selected
   *   in any instructor subform for the section, _including_ this
   *   one
   * - this subform's selected instructor, if any
   * @returns {Array} array of the "blank" option and 1+ [instructorName, instructorID]
   */
  get instructorOptions() {
    const availableInstructors = this.availableInstructors;
    const availableInstructorIDs = Object.keys(availableInstructors).map(key => parseInt(key, 10));
    const allSelectedInstructors = this.allSelectedInstructors;

    // Find all IDs that aren't already selected.
    const unselectedInstructorIDs = availableInstructorIDs.filter(function(instructor) {
      return !(allSelectedInstructors.includes(instructor));
    });

    // Look up the instructor name to create an array of options.
    const unselectedOptions = unselectedInstructorIDs.map(id => [availableInstructors[id], id]);
    const nonBlankOptions = unselectedOptions;

    // If this subform has a selected instructor, add it to the options.
    if (this.selectedInstructorID !== '') {
      nonBlankOptions.push([availableInstructors[this.selectedInstructorID], this.selectedInstructorID]);
    }

    return [['', ''], ...nonBlankOptions];
  }

  // TODO: Find better way to make static property available.
  get roleOptions() {
    return this.constructor.roleOptions;
  }

  /**
   * @summary Return whether role select and show-instructor checkbox should be disabled.
   * @returns {Boolean} true if no instructor is selected; false otherwise
   */
  get disableRelatedInputs() {
    return this.selectedInstructorID === '';
  }

  /**
   * @summary Return instructor data.
   * @returns {Object} state for instructor
   */
  get data() {
    return {
      instructor_id: this.selectedInstructorID,
      role: this.selectedRoleName,
      show_instructor: this.showInstructor
    };
  }
}

// Set options for role select as a property of the class.
Instructor.roleOptions = [['', '0'], ['Co-instructor', '1'], ['Assistant', '2']];

export default Instructor;
