/**
 * This composable has methods to act as Adaptor between VocabToolsDataStore
 * and WordFilter component.
 * Ie. to generate props from VocabToolsDataStore which stores state
 * in tree of model class in tree hierarchy of Unit, Lesson, Topic, Word etc.
 * And to handle user actions in WordFilter component to update state in VocabToolsDataStore.
 * @param {VocabToolsDataStore} vocabToolsDataStore - With reactive properties
 * which store vocab tools app state
 * @return {Object} - returns object wrapping following methods
 * getWordFilterProps,
 * retrieveLesson,
 * toggleLessonSelection,
 * toggleTopicSelection,
 * viewAllLessonsInProgram
 * viewOnlyLessonsInCourse
 */
const useWordFilterModelAdaptor = (vocabToolsDataStore) => {
  /**
   * Retrieve vocab tools data and update VocabToolsDataStore for the given lesson
   * if already not retrieved
   * @param {Object} payload - payload with lesson information
   * @param {Number} payload.lessonId - Id of the lesson
   * @param {Number} payload.unitId - Id of the unit containing the lesson
   */
  const retrieveLesson = (payload) => {
    const { lessonId, unitId } = payload;
    vocabToolsDataStore.retrieveLessonByIds(lessonId, unitId);
  };

  /**
   * Update VocabToolsDataStore to toggle selection for all topics in the given lesson
   * @param {Object} payload - payload with lesson information
   * @param {Event} payload.event - Checkbox event
   * @param {Boolean} payload.event.target.checked - Whether checkbox is checked
   * @param {Number} payload.lessonId - Id of the lesson
   * @param {Number} payload.unitId - Id of the unit containing the lesson
   */
  const toggleLessonSelection = (payload) => {
    const { event, lessonId, unitId } = payload;
    const isChecked = event.target.checked;
    vocabToolsDataStore.toggleSelectionInLessonByIds(isChecked, lessonId, unitId);
  };

  /**
   * Update VocabToolsDataStore to toggle selection for the given topic
   * @param {Object} payload - payload with lesson information
   * @param {Event} payload.event - Checkbox event
   * @param {Boolean} payload.event.target.checked - Whether checkbox is checked
   * @param {String} payload.topicName - Name of the topic
   * @param {Number} payload.lessonId - Id of the lesson containing the topic
   * @param {Number} payload.unitId - Id of the unit containing the lesson containing the topic
   */
  const toggleTopicSelection = (payload) => {
    const { event, topicName, lessonId, unitId } = payload;
    const isChecked = event.target.checked;
    vocabToolsDataStore.toggleSelectionInTopicByIds(isChecked, topicName, lessonId, unitId);
  };

  /**
   * Update VocabToolsDataStore to show all lessons in program
   */
  const viewAllLessonsInProgram = () => {
    vocabToolsDataStore.viewAllLessons = true;
  };

  /**
   * Update VocabToolsDataStore to show only lessons in course
   */
  const viewOnlyLessonsInCourse = () => {
    vocabToolsDataStore.viewAllLessons = false;
  };

  /**
   * Generate an Object containing props for WordFilter component
   * from vocabToolsDataStore which stores state in tree of model class in tree hierarchy of
   * Unit, Lesson, Topic, Word etc
   * @return {Object} - object containing props for for WordFilter component
   */
  const getWordFilterProps = () => {
    return {
      ssjrStudent: vocabToolsDataStore.ssjrStudent,
      targetLanguageCode: vocabToolsDataStore.targetLanguageCode,
      twoTier: vocabToolsDataStore.twoTier,
      units: vocabToolsDataStore.units?.map(getPropsForUnit) ?? [],
      viewAllLessons: vocabToolsDataStore.viewAllLessons,
    };
  };

  /**
   * @private
   * Generate an Object containing props for a unit for WordFilter component
   * @param {Unit} unit
   * @return {Object}
   */
  const getPropsForUnit = (unit) => {
    return {
      expanded: unit.expanded,
      id: unit.id,
      inCourse: unit.inCourse,
      lessons: unit.lessons?.map(getPropsForLesson),
      name: unit.name,
    };
  };

  /**
   * @private
   * Generate an Object containing props for a lesson for WordFilter component
   * @param {Lesson} lesson
   * @return {Object}
   */
  const getPropsForLesson = (lesson) => {
    return {
      displayName: lesson.displayName,
      expanded: lesson.expanded,
      id: lesson.id,
      inCourse: lesson.inCourse,
      selected: lessonSelectedOrAllTopicsChecked(lesson),
      topics: lesson.topics?.map(getPropsForTopic),
    };
  };

  /**
   * @private
   * Generate an Object containing props for a topic for WordFilter component
   * @param {Topic} topic
   * @return {Object}
   */
  const getPropsForTopic = (topic) => {
    return {
      isEmpty: topic.isEmpty,
      name: topic.name,
      selected: topic.selected,
      wordCount: topic.wordCount,
    };
  };

  /**
   * @private
   * Get whether lesson is selected or all of its topics are selected
   * @param {Lesson} lesson
   * @return {Boolean}
   */
  const lessonSelectedOrAllTopicsChecked = (lesson) => {
    if (lesson.topics?.length > 1) {
      const filledTopics = lesson.hasFilledTopics();
      return filledTopics.every((topic) => topic.selected);
    }
    return lesson.selected;
  };

  return {
    getWordFilterProps,
    retrieveLesson,
    toggleLessonSelection,
    toggleTopicSelection,
    viewAllLessonsInProgram,
    viewOnlyLessonsInCourse,
  };
};

export default useWordFilterModelAdaptor;
