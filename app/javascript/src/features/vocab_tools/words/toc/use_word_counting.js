/**
 * This composable provides methods for computations related to word counts
 * from props in WordFilter.
 * @return {Object} - returns object wrapping following methods
 * lessonSelectedWordsCount,
 * lessonWordCount,
 * unitSelectedWordsCount,
 * unitWordCount,
 */
const useWordCounting = () => {
  /**
   * This function calculates word count by looping through the items of the provided array
   * @param {Object[]} itemArr - having objects with properties related to word count
   * @param {Function} reducerFn - function with format of (memo, item) => reducedCount
   * @return {Number} - word count in the given array
   */
  const wordCountByReducer = (itemArr, reducerFn) => {
    const count = itemArr?.reduce((memo, item) => {
      return reducerFn(memo, item);
    }, 0);
    return count ?? 0;
  };

  /**
   * This function calculates word count in a lesson by looping through its topics
   * @param {Object} lesson - lesson having topics
   * @param {Object[]} lesson.topics - array of topics
   * @param {Number} lesson.topics[].wordCount - word count in a topic
   * @return {Number} - word count in the given lesson
   */
  const lessonWordCount = (lesson) => {
    return wordCountByReducer(lesson?.topics, (memo, topic) => {
      return memo + topic.wordCount;
    });
  };

  /**
   * This function calculates selected word count in a lesson by looping through its topics
   * @param {Object} lesson - lesson having topics
   * @param {Object[]} lesson.topics - array of topics
   * @param {Number} lesson.topics[].wordCount - word count in a topic
   * @param {Boolean} lesson.topics[].selected - whether topic is selected in word filter
   * @return {Number} - selected word count in the given lesson
   */
  const lessonSelectedWordsCount = (lesson) => {
    return wordCountByReducer(lesson?.topics, (memo, topic) => {
      return memo + (topic.selected? topic.wordCount : 0);
    });
  };

  /**
   * This function calculates word count in a unit by looping through its lessons
   * @param {Object} unit - unit having lessons
   * @param {Object[]} unit.lessons - array of lessons
   * @param {Object[]} unit.lessons[].topics - array of topics
   * @param {Number} unit.lessons[].topics[].wordCount - word count in a topic
   * @return {Number} - word count in the given unit
   */
  const unitWordCount = (unit) => {
    return wordCountByReducer(unit?.lessons, (memo, lesson) => {
      return memo + lessonWordCount(lesson);
    });
  };

  /**
   * This function calculates selected word count in a unit by looping through its lessons
   * @param {Object} unit - unit having lessons
   * @param {Object[]} unit.lessons - array of lessons
   * @param {Object[]} unit.lessons[].topics - array of topics
   * @param {Number} unit.lessons[].topics[].wordCount - word count in a topic
   * @param {Boolean} unit.lessons[].topics[].selected - whether topic is selected in word filter
   * @return {Number} - selected word count in the given unit
   */
  const unitSelectedWordsCount = (unit) => {
    return wordCountByReducer(unit?.lessons, (memo, lesson) => {
      return memo + lessonSelectedWordsCount(lesson);
    });
  };

  return {
    lessonSelectedWordsCount,
    lessonWordCount,
    unitSelectedWordsCount,
    unitWordCount,
  };
};

export default useWordCounting;
