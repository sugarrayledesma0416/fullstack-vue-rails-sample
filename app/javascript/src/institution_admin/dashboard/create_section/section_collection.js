import Section from './section.js';
import { getFromEndpoint } from '../../../shared/ajax_utils.js';

/**
 * @summary Model class for the section-subform-collection component.
 * Maintains and manages state for a collection of sections to be created.
 */
class SectionCollection {
  /**
   * @summary Instantiate the section collection.
   * The section collection initially is empty, with a count of 0.
   * @param {Integer} courseId - ID for the course
   * @param {Integer} schoolId - ID for the course's school
   */
  constructor(courseId, schoolId) {
    this.courseId = courseId;
    this.schoolId = schoolId;
    this.sections = [];
  }

  /**
   * @summary Return a promise that sets section options via AJAX and resolves.
   * This is called in `CreateSectionModal#setInitialSectionCount` via `await`.
   * The modal can't render section subforms without the section options (which
   * include the available additional instructors), so it waits for the
   * promise to resolve and then sets the section count to 1 to initiate
   * drawing the subforms.
   * @returns {Promise} promise that resolves on getting data from AJAX request
   */
  getSectionOptions() {
    return new Promise(resolve => {
      getFromEndpoint(
        `${location.origin}/institution_admin/section_options/${this.courseId}?school_id=${this.schoolId}`,
        (data) => {
          this.sectionOptions = data;
          resolve();
        })
    });
  }

  /**
   * @summary Update the section collection to match the given section count.
   * This method preserves the state of already-in-progress sections when the
   * user changes the section count.
   *
   * If the user adds more sections, it appends enough new section objects to
   * make the collection the right size.
   *
   * If the user removes sections, it removes sections from the end of the
   * collection.
   *
   * @param {Integer} count - the new section count
   */
  updateSectionCount(count) {
    const sectionCount = this.sections.length;

    if (count > sectionCount) {
      /**
       * If count > current count,
       *   create (count - current count) "blank" sections and append to collection.
       */
      const extraSectionCount = count - sectionCount;
      let extraSections = [...new Array(extraSectionCount)].map(() => {
        return new Section(this.sectionOptions);
      });
      this.sections.splice(sectionCount,
                           0,
                           ...extraSections)
    } else {
      /**
       * If count < current count,
       *   remove last (current count - count) sections from collection.
       */
      this.sections.splice(count);
    }
  }

  setSections(sectionData) {
    this.sections = sectionData.sections.map(section => new Section(this.sectionOptions, section));
  }

  /**
   * @summary Validates state of collection.
   * This validation checks for two conditions:
   * 1. Each section in the collection is valid.
   * 2. The section names are distinct: no duplicates.
   *
   * @returns {Boolean} true if collection is valid; false otherwise
   */
  valid() {
    if (!this.sections.every(section => section.valid())) {
      return;
    }

    // Check that there are no duplicate section names.
    const sectionNames = this.sections.map(section => section.sectionName);
    return sectionNames.length === [...new Set(sectionNames)].length;
  }

  mutableCopy(sectionId) {
    let section = this.sections.find(s => s.id == sectionId);
    let sectionCollection = new SectionCollection(this.courseId, this.schoolId);
    sectionCollection.sections = [section.mutableCopy];
    sectionCollection.sectionOptions = this.sectionOptions;

    return sectionCollection;
  }

  /**
   * @summary Return data for all sections in the collection.
   * @returns {Array} array of section-data objects
   */
  get data() {
    return this.sections.map(section => section.data)
  }
};

export default SectionCollection;
