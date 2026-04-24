/**
 * Get lesson/ unit info from query string
 * @return {Object}
 */
const getInfoFromUrl = () => {
  const query = window.location.search.substr(1);
  const result = {};
  query.split('&').forEach((part) => {
    const item = part.split('=');
    result[item[0]] = decodeURIComponent(item[1]);
  });
  return result;
};

/**
 * Find lesson instance from localStore by lesson id and unit id.
 * @param {Object} localStore - Reactive object which stores vocab tools app state
 * @param {Number} lessonId - Id of the lesson
 * @param {Number} unitId - Id of the unit containing the lesson
 * @return {Lesson} - lesson instance
 */
const getLessonInstanceByIds = (localStore, lessonId, unitId) => {
  const unitInstance = localStore.units?.find((unit) => unit.id === unitId);
  return unitInstance?.lessons?.find((lesson) => lesson.id === lessonId);
};

/**
 * Get whether given item is a lesson.
 * @param {Object} item
 * @return {Boolean}
 */
const isLesson = (item) => {
  return item.topics !== undefined;
};

/**
 * Get whether given item is a unit.
 * @param {Object} item
 * @return {Boolean}
 */
const isUnit = (item) => {
  return item.lessons !== undefined;
};

export { getInfoFromUrl, getLessonInstanceByIds, isLesson, isUnit };
