/**
 * Class representing Unit.
 */
class Unit {
  /**
   * Instantiate the Unit class.
   * @param {Object} unit - Unit for vocab tools.
   * @param {Boolean} unit.expanded - Tells whether unit disclosure is expanded in toc.
   * @param {Number} unit.id - Id of a unit.
   * @param {Boolean} unit.in_course - Tells if unit is present in course.
   * @param {String} unit.name - Name of a unit.
   * @param {Boolean} unit.two_tier - Tells whether toc has singleTier view or twoTier.
   * @param {Array} unit.lessons - An Array of lesson corresponding to the unit.
   */
  constructor(unit) {
    this.expanded = unit.expanded;
    this.id = unit.id;
    this.inCourse = unit.inCourse;
    this.lessons = unit.lessons;
    this.name = unit.name;
    this.twoTier = unit.twoTier;
  }

  /**
   * Get Words corresponding to the unit which are selected.
   * @return {Array} - words corresponding to the unit which are selected.
   */
  selectedWords() {
    // Set is used to make collection of words as unique. Basically, applying union.
    return this.lessons.reduce(
      (initialArr, lesson) => [...new Set([...initialArr, ...lesson.selectedWords()])],
      []
    );
  }

  /**
   * Get word count for a unit.
   * @return {Number} - Word count for a unit.
   */
  wordCount() {
    return this.lessons.reduce(
      (initialValue, lesson) => initialValue + lesson.wordCount, 0
    );
  }
}

export default Unit;
