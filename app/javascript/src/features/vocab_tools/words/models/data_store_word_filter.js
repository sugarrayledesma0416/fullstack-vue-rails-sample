import {
  getLessonInstanceByIds,
  isLesson,
  isUnit,
} from 'features/vocab_tools/words/data_store_helpers';

/**
 * This class provides methods related to word filtering ie to update vocab tools app state
 * via topic/ lesson selection change.
 */
export default class DataStoreWordFilter {
  /**
   * Store reference of reactive object which stores vocab tools app state
   * @constructor
   * @param {Object} localStore - Reactive object which stores vocab tools app state
   * @param {DataStoreRetriever} dataStoreRetriever
   * @param {Funtion} dataStoreRetriever.retrieveLesson - Method to retrieve data for a lesson
   * @param {Funtion} dataStoreRetriever.retrieveUnit - Method to retrieve data for a unit
   */
  constructor(localStore, dataStoreRetriever) {
    this.localStore = localStore;
    this.dataStoreRetriever = dataStoreRetriever;
  }

  /**
   * Update localStore to toggle selection for all topics in the given lesson.
   * @param {Boolean} isSelected - New value of whether topic is selected
   * @param {Number} lessonId - Id of the lesson
   * @param {Number} unitId - Id of the unit containing the lesson
   */
  toggleSelectionInLessonByIds(isSelected, lessonId, unitId) {
    const lesson = getLessonInstanceByIds(this.localStore, lessonId, unitId);
    this.toggleSelectionInLesson(isSelected, lesson);
  }

  /**
   * Update localStore to toggle selection for all topics in the given lesson.
   * @param {Boolean} isSelected - New value of whether topic is selected
   * @param {String} topicName - Name of the topic
   * @param {Number} lessonId - Id of the lesson containing the topic
   * @param {Number} unitId - Id of the unit containing the lesson containing the topic
   */
  toggleSelectionInTopicByIds(isSelected, topicName, lessonId, unitId) {
    const lesson = getLessonInstanceByIds(this.localStore, lessonId, unitId);
    const topicInstance = lesson?.topics?.find((topic) => topic.name === topicName);
    if (topicInstance) {
      topicInstance.selected = isSelected;
    }
  }

  /**
   * @private
   * Update localStore to toggle all topics selection for a given lesson.
   * @param {Boolean} isSelected - New value of whether topic is selected
   * @param {Lesson} lesson
   */
  async toggleSelectionInLesson(isSelected, lesson) {
    // Get lesson data in case checkbox is clicked before disclosure is clicked.
    await this.dataStoreRetriever.retrieveLesson(lesson);

    // Update selected values once retrieveLesson completes
    lesson.topics?.forEach((topic) => {
      if (!topic.isEmpty) {
        topic.selected = isSelected;
      }
    });
    lesson.selected = isSelected;
  }

  /**
   * @private
   * Update localStore to toggle all topics selection for a given unit.
   * @param {Boolean} isSelected - New value of whether topic is selected
   * @param {Unit} unit
   */
  async toggleSelectionInUnit(isSelected, unit) {
    if (isSelected) {
      await this.dataStoreRetriever.retrieveUnit(unit);
    }

    // Update selected values once retrieveUnit completes
    unit.lessons?.forEach((lesson) => {
      lesson.selected = isSelected;
      this.toggleSelectionInLesson(isSelected, lesson);
    });
  }

  /**
   * @private
   * Update localStore to toggle all topics selection for a given unit or lesson.
   * @param {Boolean} isSelected - New value of whether topic is selected
   * @param {Unit|Lesson} item
   */
  toggleSelectionInUnitOrLesson(isSelected, item) {
    if (isLesson(item)) {
      this.toggleSelectionInLesson(isSelected, item);
    } else if (isUnit(item)) {
      this.toggleSelectionInUnit(isSelected, item);
    }
  }
}
