/**
 * @typeDef {DayOfWeekObject}
 * @property {string} name
 * @property {boolean} name
 * @property {number} name
 */

/**
 * This return an object representing default selection values of weekdays in 0-6 format.
 * 0 stands for Sunday & 6 stands for Saturday.
 * @return {Array.<DayOfWeekObject>}
 */
export function getDefaultDaysOfWeek() {
  return [
    { name: 'Sunday', selected: false, value: 0 },
    { name: 'Monday', selected: false, value: 1 },
    { name: 'Tuesday', selected: false, value: 2 },
    { name: 'Wednesday', selected: false, value: 3 },
    { name: 'Thursday', selected: false, value: 4 },
    { name: 'Friday', selected: false, value: 5 },
    { name: 'Saturday', selected: false, value: 6 },
  ];
}
