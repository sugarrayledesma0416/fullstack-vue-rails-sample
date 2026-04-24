import AdditionalInstructorCollection from './additional_instructor_collection.js';

/**
 * @summary Model class for the section subform.
 * This class maintains and manages the state of one section subform in the
 * create-section modal's section-subform collection.
 */
class Section {
  /**
   * @summary Instantiate the model.
   * The model is set to this initial state:
   * - section name is blank
   * - the first section template from the section options is selected
   * - the course owner's name is to be shown in the section preview
   *
   * The model is also assigned a collection of additional instructors.
   *
   * @param {Object} sectionOptions - the section-options data from the endpoint
   */
  constructor(sectionOptions, sectionData = {}) {
    this.sectionOptions = sectionOptions;

    /**
     * Save sectionData in object.
     *
     * We can use it, along with sectionOptions, to spin off a section object
     * for the edit-section modal that can be mutated without affecting the original
     * object in case the user cancels the edit.
     */
    this.sectionData = sectionData;

    this.init(sectionOptions, sectionData);
  }

  init(sectionOptions, sectionData) {
    this.sectionName = sectionData.name || '';
    this.id = sectionData.id;

    /**
     * Assign names of existing sections in course.
     *
     * This will be used to validate that the section's name
     * doesn't duplicate an existing name. If the section is being edited,
     * it already has a name; that name is filtered out here so that the
     * section won't fail the validation.
     */
    this.existingSectionNames = sectionOptions.existing_section_names
                                              .filter(name => name != this.sectionName);

    // need to get source template ID.
    // if no source template ID, select first template as default. */
    this.selectedTemplate = sectionData.source_template_id || sectionOptions.section_template_options[0][1];

    this.instructor = sectionOptions.course_owner_name;

    this.showOwner = sectionData.show_owner === undefined ? true : sectionData.show_owner;

    let additionalInstructorData = sectionData.additional_instructors;

    this.additionalInstructorCollection = new AdditionalInstructorCollection(
      sectionOptions.additional_instructor_options,
      additionalInstructorData
    );
  }

  /**
   * @summary Validate that section name is not blank.
   * @returns {Boolean} true if name is not blank, false otherwise
   */
  sectionNamePopulated() {
    return this.sectionName !== '';
  }

  /**
   * @summary Validate that name is not already taken by existing section.
   */
  sectionNameNew() {
    return !(this.existingSectionNames.includes(this.sectionName));
  }

  /**
   * @summary Validate that all additional instructors are valid.
   * @returns {Boolean} true if all valid, false otherwise
   */
  additionalInstructorsValid() {
    return this.additionalInstructorCollection.valid();
  }

  /**
   * @summary Validate that at least one instructor is shown in preview.
   * @returns {Boolean} true if owner or another instructor is shown, false otherwise
   */
  atLeastOneInstructorShown() {
    /* The course owner's name is to be shown, OR at least one instructor has "show instructor" as true. */
    return this.showOwner || this.additionalInstructorCollection.atLeastOneAdditionalInstructorShown();
  }

  /**
   * @summary Validate that all validations return true.
   * This method uses `every` to turn an array of validation functions
   * into a series of guard clauses.
   *
   * Execution of functions is deferred until every() begins running.
   * every() will short-circuit on the first function to return `false`,
   * and subsequent items in the array will not execute.
   * @returns {Boolean} true if all true, false otherwise
   */
  valid() {
    let validations = [
      this.sectionNamePopulated,
      this.sectionNameNew,
      this.additionalInstructorsValid,
      this.atLeastOneInstructorShown
    ];

    return validations.every(item => item.apply(this));
  }

  /**
   * @summary Return data for the section to be created.
   * @returns {Object} data for the section
   */
  get data() {
    return {
      id: this.id,
      name: this.sectionName,
      template_id: this.selectedTemplate,
      hide_owner_name: !this.showOwner,
      additional_instructors: this.additionalInstructorCollection.data
    };
  }

  get mutableCopy() {
    return new Section(this.sectionOptions, this.sectionData);
  }
}

export default Section;
