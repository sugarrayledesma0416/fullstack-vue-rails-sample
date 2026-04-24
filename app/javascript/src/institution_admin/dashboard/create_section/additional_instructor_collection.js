import Instructor from './instructor.js';

/**
 * @summary Model for a collection of additional instructors.
 * Model class for instructor-subform-collection component.
 * This class is responsible for maintaining and validating
 * the state of the collection.
 */
class AdditionalInstructorCollection {
  /**
   * @summary Instantiate the model.
   * Initialize object with data for all available instructors,
   * plus a collection with one instructor.
   *
   * NOTE: An "instructor" is not a specific instructor, but a model for the
   * instructor subform - i.e., an instructor selection (which may be blank).
   *
   * @param {Object} additionalInstructorOptions - data for instructors that may be chosen
   */
  constructor(additionalInstructorOptions, instructorData) {
    this.availableInstructors = additionalInstructorOptions;
    this.availableInstructorsCount = Object.keys(additionalInstructorOptions).length;
    if (instructorData) {
      this.additionalInstructors = instructorData.map(instructor => new Instructor(this.availableInstructors, instructor))
      this.updateSelectedInstructors();
    } else {
      this.additionalInstructors = [];
      this.addInstructor();
    }
  }

  /**
   * @summary Add an instructor to the collection.
   * Validate first that collection size does not already match the count of
   * available instructors, since user cannot select more instructors than
   * are available.
   */
  addInstructor() {
    if (this.canAddInstructors) {
      this.additionalInstructors.push(new Instructor(this.availableInstructors));
    }
  }

  /**
   * @summary Return whether collection has room to add instructors.
   * @returns {Boolean} whether there are fewer additional instructors than available instructors.
   */
  get canAddInstructors() {
    return this.additionalInstructors.length < this.availableInstructorsCount;
  }

  /**
   * @summary Update models based on an instructor selection.
   * Update the instructor model for the form element that has changed.
   * Also update the other instructor models in the collection based on the current set
   * of selected instructor IDs.
   * @param {Integer} instructorIndex - the instructor model's index in the collection
   * @param {String} selectedInstructorID - the selected value for the instructor
   */
  updateSelectedInstructors(instructorIndex=undefined, selectedInstructorID=undefined) {
    /**
     * If a particular instructor subform and selected instructor are specified,
     *   update the instructor model to set its selected instructor ID.
     *
     * The method is called without instructorIndex or selectedInstructorID when
     *   the user clicks "Add more" to add an instructor subform.
     */
    if (instructorIndex !== undefined && selectedInstructorID !== undefined) {
      /**
       * If the selected ID is an empty string, we can use that as the selection.
       * Otherwise, we should be able to parse it as an int.
       *
       * Attempting to parse the empty string as an int returns NaN and causes
       * a bug.
       */
      let selection = selectedInstructorID === '' ? '' : parseInt(selectedInstructorID, 10);

      this.additionalInstructors[instructorIndex].selectedInstructorID = selection;
    }

    /**
     * Get list of selected instructor IDs in collection.
     * Update each instructor in collection so that its subform doesn't list instructor IDs
     * selected in other subforms. */
    const allSelectedInstructors = this.additionalInstructors.map((instructor) => {
      return instructor.selectedInstructorID;
    });

    this.additionalInstructors.forEach((instructor) => {
      instructor.updateSelectedInstructors(allSelectedInstructors);
    });
  }

  /**
   * @summary Validate that all instructors are in a valid state for submission.
   * @returns {Boolean} whether all instructors are valid
   */
  valid() {
    /* If not all instructors are valid, return (null value will evaluate as false). */
    if (!this.additionalInstructors.every(instructor => instructor.valid())) {
      return;
    }

    return true;
  }

  /**
   * @summary Return whether at least one instructor in collection is to be shown in preview.
   * @returns {Boolean} whether `showInstructor` is true for all instructors
   */
  atLeastOneAdditionalInstructorShown() {
    /* At least one instructor has "show instructor" as true. */
    return this.additionalInstructors.some(instructor => instructor.showInstructor);
  }

  /**
   * @summary Filter out instructors with no selected ID.
   * @returns {Array} instructors with non-blank selected ID
   */
  get nonBlankInstructors() {
    return this.additionalInstructors.filter((instructor) => {
      return instructor.selectedInstructorID !== '';
    });
  }

  /**
   * @summary Return data to be aggregated in submission to endpoint.
   * @returns {Object} state for instructors with ID selected
   */
  get data() {
    return this.nonBlankInstructors.map((instructor) => {
      return {
        instructor_id: instructor.selectedInstructorID,
        role: instructor.selectedRoleName,
        show: instructor.showInstructor
      };
    })
  }
}

export default AdditionalInstructorCollection;
