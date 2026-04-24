/** Class representing a UnitRange. */
class UnitRange {
  /**
   * @typeDef {UnitObject}
   * @property {string} guid
   * @property {number} id
   * @property {number} media_item_id
   * @property {number} program_id
   * @property {string} name
   * @property {string} index
   * @property {boolean} released
   * @property {number} rank
   * @property {number} toc_location
   */

  /**
   * Constructor of UnitRange.
   * @param {number} firstUnitIndex - index of first unit.
   * @param {number} lastUnitIndex - index of last unit.
   * @param {Array.<UnitObject>} units - list of units.
   */
  constructor(firstUnitIndex, lastUnitIndex, units) {
    this.firstUnitIndex = firstUnitIndex;
    this.lastUnitIndex = lastUnitIndex;
    this.units = units;
    if (units) {
      // map of all unit ids to their sorted index
      this.unitIdToIndexMap = units.map((unit) => unit.id).reduce((memo, unitId, index) => {
        memo[unitId] = String(index);
        return memo;
      }, {});
    } else {
      this.unitIdToIndexMap = {};
    }
  }

  /**
   * get the count of unit range.
   * @return {number} - count.
   */
  get count() {
    return Math.max(
      (parseInt(this.lastUnitIndex, 10) - parseInt(this.firstUnitIndex, 10) + 1),
      0
    );
  }

  /**
   * get the first unit Id if exits in units.
   * @return {number} - first unit id.
   */
  get firstUnitId() {
    return this.unitId(this.firstUnitIndex);
  }

  /**
   * get the last unit Id if exits in units.
   * @return {number} - last unit id.
   */
  get lastUnitId() {
    return this.unitId(this.lastUnitIndex);
  }

  /**
   * check if unit range is valid.
   * @return {boolean}
   */
  get isValid() {
    const lastUnitIndex = parseInt(this.lastUnitIndex, 10);
    const firstUnitIndex = parseInt(this.firstUnitIndex, 10);
    return lastUnitIndex >= firstUnitIndex;
  }

  /**
   * Looping through the unit range.
   * @param {Function} callback
   */
  each(callback) {
    const lastUnitIndex = parseInt(this.lastUnitIndex, 10);
    const firstUnitIndex = parseInt(this.firstUnitIndex, 10);
    for (let i = firstUnitIndex, j = lastUnitIndex; i <= j; i++) {
      callback(i);
    }
  }

  /**
   * checks if activity unit id is included in the unit range.
   * @param {number} activityUnitId - activity unit id.
   * @return {boolean}
   */
  includes(activityUnitId) {
    const index = parseInt(this.unitIdToIndexMap[activityUnitId], 10);
    if (Number.isFinite(index)) {
      return index <= parseInt(this.lastUnitIndex, 10) &&
        index >= parseInt(this.firstUnitIndex, 10);
    }
    return false;
  }

  /**
   * @private
   * returns the unit id.
   * @param {number} unitIndex - index of the unit
   * @return {number} - unit id
   */
  unitId(unitIndex) {
    const unit = this.units[parseInt(unitIndex, 10)];
    return unit && unit.id;
  }
}

export default UnitRange;
