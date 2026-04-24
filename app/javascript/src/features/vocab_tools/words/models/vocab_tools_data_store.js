import { reactive } from 'vue';
import DataStoreRetriever from './data_store_retriever';
import DataStoreUserWord from './data_store_user_word';
import DataStoreWordFilter from './data_store_word_filter';

/**
 * This class initializes vocab tools app state and has methods to manipulate the app state.
 */
export default class VocabToolsDataStore {
  /**
   * Initialize reactive object which stores vocab tools app state
   * @constructor
   * @param {Function} setLanguageCallback - callback to set Target Language
   */
  constructor(setLanguageCallback) {
    // Reactive object which stores vocab tools app state
    this.localStore = reactive({
      enrolled: false,
      isTranslationHidden: false,
      ssjrStudent: false,
      targetLanguage: '',
      targetLanguageCode: '',
      twoTier: false,
      units: [],
      viewAllLessons: false,
      vocabHasDefinition: false,
    });
    this.dataStoreRetriever = new DataStoreRetriever(this.localStore);
    this.dataStoreWords = new DataStoreUserWord(this.localStore);
    this.dataStoreWordFilter = new DataStoreWordFilter(this.localStore, this.dataStoreRetriever);

    this.dataStoreRetriever.init(setLanguageCallback);
  }

  /**
   * Get whether enrolled
   * @return {boolean}
   */
  get enrolled() {
    return this.localStore.enrolled;
  }

  /**
   * Get whether translation column should be hidden and
   * only target and definition column should be shown
   * @return {boolean}
   */
  get isTranslationHidden() {
    return this.localStore.isTranslationHidden;
  }

  /**
   * Get target language
   * @return {string}
   */
  get targetLanguage() {
    return this.localStore.targetLanguage;
  }

  /**
   * Get target language code
   * @return {string}
   */
  get targetLanguageCode() {
    return this.localStore.targetLanguageCode;
  }

  /**
   * Set target language code
   * @param {string} value - Target language code
   */
  set targetLanguageCode(value) {
    this.localStore.targetLanguageCode = value;
  }

  /**
   * Get whether WordFilter UI is two tier ie showing unit and lesson disclosure both
   * @return {boolean}
   */
  get twoTier() {
    return this.localStore.twoTier;
  }

  /**
   * Get array of Unit instances
   * @return {Unit[]}
   */
  get units() {
    return this.localStore.units;
  }

  /**
   * Get whether all lessons are shown
   * @return {boolean}
   */
  get viewAllLessons() {
    return this.localStore.viewAllLessons;
  }

  /**
   * Set whether all lessons are shown
   * @param {boolean} value - new value
   */
  set viewAllLessons(value) {
    this.localStore.viewAllLessons = value;
  }

  /**
   * Get whether to show Definition column
   * @return {boolean}
   */
  get vocabHasDefinition() {
    return this.localStore.vocabHasDefinition;
  }

  /**
   * Get whether the program is supersite junior and current user is student
   * @return {boolean}
   */
  get ssjrStudent() {
    return this.localStore.ssjrStudent;
  }

  /**
   * Update localStore by adding user word to the list of words for the lesson.
   * @param {number} unitId - Id of the corresponding unit.
   * @param {number} lessonId - Id of the corresponding lesson.
   * @param {Object} word - Word to be added.
   */
  addUserWord(unitId, lessonId, word) {
    this.dataStoreWords.addUserWord(unitId, lessonId, word);
  }

  /**
   * Update localStore by removing user word from the list of words for the lesson.
   * @param {number} unitId - Id of the corresponding unit.
   * @param {number} lessonId - Id of the corresponding lesson.
   * @param {Object} word - Word to remove.
   */
  removeUserWord(unitId, lessonId, word) {
    this.dataStoreWords.removeUserWord(unitId, lessonId, word);
  }

  /**
   * Update localStore by retrieving vocab tools data for the given lesson
   * if already not retrieved. This method is for lazy loading data after initialization.
   * @param {number} lessonId - Id of the lesson
   * @param {number} unitId - Id of the unit containing the lesson
   */
  retrieveLessonByIds(lessonId, unitId) {
    this.dataStoreRetriever.retrieveLessonByIds(lessonId, unitId, true);
  }

  /**
   * Update localStore to toggle selection for all topics in the given lesson.
   * @param {boolean} isSelected - New value of whether topic is selected
   * @param {number} lessonId - Id of the lesson
   * @param {number} unitId - Id of the unit containing the lesson
   */
  toggleSelectionInLessonByIds(isSelected, lessonId, unitId) {
    this.dataStoreWordFilter.toggleSelectionInLessonByIds(isSelected, lessonId, unitId);
  }

  /**
   * Update localStore to toggle selection for all topics in the given lesson.
   * @param {boolean} isSelected - New value of whether topic is selected
   * @param {string} topicName - Name of the topic
   * @param {number} lessonId - Id of the lesson containing the topic
   * @param {number} unitId - Id of the unit containing the lesson containing the topic
   */
  toggleSelectionInTopicByIds(isSelected, topicName, lessonId, unitId) {
    this.dataStoreWordFilter.toggleSelectionInTopicByIds(isSelected, topicName, lessonId, unitId);
  }

  /**
   * Update localStore by updating user word to the list of words for the lesson.
   * @param {number} unitId - Id of the corresponding unit.
   * @param {number} lessonId - Id of the corresponding lesson.
   * @param {Object} wordToUpdate - word to update.
   */
  updateUserWord(unitId, lessonId, wordToUpdate) {
    this.dataStoreWords.updateUserWord(unitId, lessonId, wordToUpdate);
  }
}
