/** Class representing a group of aligned items, belonging to
 * a single unit, grouped by lesson and concept.
 */
class UnitItem {
  /**
   * @param {String} unitId - the unitId for unitAlignedItems
   * @param {Object} unitAlignedItems - aligned item data grouped by lessons, concepts
   */
  constructor(unitId, unitAlignedItems) {
    this.items = unitAlignedItems;
    this.unitIdStr = unitId;
  }

  /**
   * returns the unitId as a number
   * @return {Number}
   */
  get unitId() {
    return parseInt(this.unitIdStr);
  }

  /**
   * @param {Array.<Number>} selectedTocItems
   * @return {boolean} - whether or not the unit is selected for display
   */
  isUnitVisible(selectedTocItems) {
    return selectedTocItems.includes(this.unitId);
  }

  /**
   * @param { Number } conceptId - the id of the concept.
   * @param { Number } lessonId - the id of the lesson.
   * @return { String } the strand color for the lesson and concept.
   */
  conceptBackgroundColor(conceptId, lessonId) {
    // Every activity in the concept has the same strand color so we can pick the first
    return this.items[lessonId][conceptId][0].strand_color;
  }
}

export default UnitItem;
