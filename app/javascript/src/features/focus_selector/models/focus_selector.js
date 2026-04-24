/** Class representing the FocusSelectorApp main model. */
class FocusSelector {
  /**
   * Instantiate the FocusSelector class.
   * @constructor
   * @param {String} sectionsJson - JSON formatted string representing an array of section objects
   */
  constructor(sectionsJson) {
    this._sections = this.parseSections(sectionsJson);
  }

  /**
   * Retrieve sections relative to the current program
   * @return {[Object]}
   */
  get sections() {
    return this._sections;
  }

  /**
   * Parse sections JSON
   * @param {String} sectionsJson - JSON formatted string representing an array of section objects
   * @return {[Object]}
   */
  parseSections(sectionsJson) {
    const sections = JSON.parse(sectionsJson);

    if (Array.isArray(sections)) {
      sections.forEach((section) => {
        if (section.id) {
          section['focusInputValue'] = this.focusInputValue(section.id);
          section['sectionFormId'] = this.sectionFormId(section.id);
        }
      });

      return sections;
    } else {
      throw new Error('sections is not an array');
    }
  }

  /**
   * Get the input named focus' value from the sectionId
   * @param {String} sectionId - String representing the id of a section
   * @return {String}
   */
  focusInputValue(sectionId) {
    return 'Section,' + sectionId;
  }

  /**
   * Get HTML id attribute string for a section
   * @param {String} sectionId - String representing the id of a section
   * @return {String}
   */
  sectionFormId(sectionId) {
    return 'section-form-' + sectionId;
  }
}

export default FocusSelector;
