import Unit from 'models/vocab_tools/unit';
import Lesson from 'models/vocab_tools/lesson';
import WordList from 'models/vocab_tools/word_list';
import {
  getInfoFromUrl,
  getLessonInstanceByIds,
  isLesson,
  isUnit,
} from 'features/vocab_tools/words/data_store_helpers';

/**
 * This class provides methods to update vocab tools app state via retrieving data.
 */
export default class DataStoreRetriever {
  /**
   * Store reference of reactive object which stores vocab tools app state
   * @constructor
   * @param {Object} localStore - Reactive object which stores vocab tools app state
   */
  constructor(localStore) {
    this.localStore = localStore;
  }

  /**
   * Update localStore by retrieving vocab tools data for given lesson if already not retrieved.
   * @param {Lesson} lesson
   * @param {boolean} bToggleDisclosure - Whether to toggle the state (ie expanded or not)
   * for the lesson disclosure.
   * This param is added to handle following use cases:
   * - When disclosure is toggled in ui after lesson words are already retrieved
   * - When there are no words in a retrieved lesson
   */
  async retrieveLesson(lesson, bToggleDisclosure) {
    if (lesson.isRetrieved) {
      bToggleDisclosure && this.toggleDisclosureState(lesson);
      return;
    }

    await WordList.forLesson(lesson).then((payload) => {
      lesson.isRetrieved = true;
      const lessonsToAdd = WordList.organize(payload.words_data.words);
      this.updateLessonsWithTopics(lesson.parent.lessons, lessonsToAdd);

      // Update expanded state in case its not updated yet.
      if (bToggleDisclosure && !lessonsToAdd.length) {
        this.toggleDisclosureState(lesson);
      }
    });
  }

  /**
   * Update localStore by retrieving vocab tools data for the given lesson
   * if already not retrieved. This method is for lazy loading data after initialization.
   * @param {number} lessonId - Id of the lesson
   * @param {number} unitId - Id of the unit containing the lesson
   * @param {boolean} bToggleDisclosure - Whether to toggle the state (ie expanded or not)
   * for the lesson disclosure.
   */
  retrieveLessonByIds(lessonId, unitId, bToggleDisclosure) {
    const lesson = getLessonInstanceByIds(this.localStore, lessonId, unitId);
    this.retrieveLesson(lesson, bToggleDisclosure);
  }

  /**
   * Update localStore by retrieving vocab tools data for given unit if already not retrieved.
   * @param {Unit} unit
   */
  async retrieveUnit(unit) {
    await Promise.all(unit.lessons?.map(async (lesson) => {
      await this.retrieveLesson(lesson);
    }));
  }

  /**
   * @private
   * Prepare instance of Unit from unit data and add topics etc.
   * @param {Object} unitData - Unit data
   * @param {number} unitId
   * @param {Lesson[]} lessonsToAdd - Lessons to add in lessons array
   * @return {Unit}
   */
  buildUnitInstance(unitData, unitId, lessonsToAdd) {
    const unitInstance = this.getUnitInstance(unitData, unitId);
    const lessonsInUnit = unitInstance.lessons;
    const retrievedLessonIds = lessonsToAdd.map((lesson) => lesson.id);
    // Set isRetrieved flag for all the retrieved lessons
    lessonsInUnit.forEach((lesson) => {
      if (retrievedLessonIds.includes(lesson.id)) {
        lesson.isRetrieved = true;
      }
    });
    this.updateLessonsWithTopics(lessonsInUnit, lessonsToAdd);
    return unitInstance;
  }

  /**
   * @private
   * Calculate Vocab Tools state, organize data and generate model in Unit /Lesson hierarchy
   * @param {Object} unitsDataFromStorage - Units data from VHL.Storage
   * @param {Object} payload - Response from WordList.forLesson() call
   * @param {boolean} payload.words_data.program_metadata.vocab_english - Whether to show only
   * English and Definition column
   * @param {boolean} payload.words_data.program_metadata.vocab_has_definition - Whether to show
   * Definition column
   * @param {boolean} payload.words_data.program_metadata.ssjr_student - Whether the program
   * is supersite junior and current user is student
   * @param {Array} payload.words_data.words - Array of words
   * @return {Object} state - Vocab Tools state
   * @return {boolean} state.enrolled -
   * @return {boolean} state.isTranslationHidden - Whether translation column should be hidden and
   * only target and definition column should be shown
   * @return {string} state.targetLanguage -
   * @return {boolean} state.twoTier - Whether WordFilter UI is two tier
   * ie showing unit and lesson disclosure both
   * @return {Unit[]} state.units - array of Unit instances
   * @return {boolean} state.viewAllLessons - Whether all lessons are shown
   * @return {boolean} state.vocabHasDefinition - Whether to show Definition column
   */
  getInitialState(unitsDataFromStorage, payload) {
    const unitsData = unitsDataFromStorage || payload.course_data;
    const viewAllLessons = unitsData.view_all_lessons || false;
    const enrolled = unitsData.enrolled;
    // This is expected that when isTranslationHidden is true then target language is English
    // and vocabHasDefinition is true.
    const isTranslationHidden = payload.words_data.program_metadata.hide_translation;
    const vocabHasDefinition = payload.words_data.program_metadata.vocab_has_definition;
    const ssjrStudent = payload.words_data.program_metadata.ssjr_student;
    const targetLanguage = unitsData.language_name;
    // Switch to two tier displaying mode (Units and Lessons)
    // even if we have at least one two tired unit
    const twoTier = unitsData.units.some((unit) => unit.two_tier);

    // this can be a unit or a lesson
    const queryStringData = getInfoFromUrl();
    const unitId = parseInt(queryStringData.unit_id, 10);
    const lessonsToAdd = WordList.organize(payload.words_data.words, true);
    const units = [];
    unitsData.units.forEach((unit) => {
      const unitInstance = this.buildUnitInstance(unit, unitId, lessonsToAdd);
      units.push(unitInstance);
    });

    return {
      enrolled,
      isTranslationHidden,
      ssjrStudent,
      targetLanguage,
      twoTier,
      units,
      viewAllLessons,
      vocabHasDefinition,
    };
  }

  /**
   * @private
   * Get 'My Words' Topic instance from the array of topics.
   * @param {Topic[]} topics - Array of topics
   * @return {Topic} - 'My Words' Topic
   */
  getMyWordsTopic(topics) {
    return topics?.find((topic) => topic.name === 'My Words');
  }

  /**
   * @private
   * Get instance of Unit from unit data. Unit would have instance of Lessons in it.
   * @param {Object} unit - Unit data
   * @param {number} unitId
   * @return {Unit}
   */
  getUnitInstance(unit, unitId) {
    const unitInstance = new Unit({
      expanded: unit.id == unitId,
      id: unit.id,
      inCourse: unit.in_course,
      lessons: [],
      name: unit.name,
      twoTier: unit.two_tier,
    });

    unit.lessons.forEach((lesson) => {
      const lessonInstance = new Lesson({
        displayName: lesson.label || lesson.name,
        expanded: false,
        id: lesson.id,
        inCourse: unit.in_course,
        label: lesson.label,
        name: lesson.name,
        parent: unitInstance,
      });
      unitInstance.lessons.push(lessonInstance);
    });
    return unitInstance;
  }

  /**
   * @param {Function} setLanguageCallback - callback to set Target Language
   * Fetch vocab tools words data, organize data and generate model in Unit /Lesson hierarchy
   */
  async init(setLanguageCallback) {
    await WordList.forLesson().then((payload) => {
      const unitsDataFromStorage = VHL.Storage.get('units_data', { json: true });
      const initialState = this.getInitialState(unitsDataFromStorage, payload);

      // This callback sets VHL.VocabTools.currentTargetLanguage before localStore is updated
      if (typeof setLanguageCallback === 'function') {
        setLanguageCallback(initialState.targetLanguage);
      }
      Object.assign(this.localStore, initialState);
    });
  }

  /**
   * @private
   * Update localStore by retrieving vocab tools data for given unit or lesson
   * if already not retrieved.
   * @param {Unit|Lesson} item
   */
  retrieveUnitOrLesson(item) {
    if (isLesson(item)) {
      this.retrieveLesson(item);
    } else if (isUnit(item)) {
      this.retrieveUnit(item);
    }
  }

  /**
   * @private
   * If 'My Words' is already selected in datastore then update lessonToAdd to keep it selected.
   * @param {Lesson} lessonInStore - Lesson in vocab tools app state
   * @param {Lesson} lessonToAdd - Lesson to add in lessons array
   */
  setSelectionOnMyWords(lessonInStore, lessonToAdd) {
    const myWordsTopic = this.getMyWordsTopic(lessonInStore.topics);
    if (myWordsTopic?.selected) {
      const myWordsInNewData = this.getMyWordsTopic(lessonToAdd.topics);
      if (myWordsInNewData) myWordsInNewData.selected = true;
    }
  }

  /**
   * @private
   * Toggle state of a lesson disclosure in localStore.
   * @param {Lesson} lesson
   */
  toggleDisclosureState(lesson) {
    const lessonsInUnit = lesson.parent.lessons;
    const lessonInStore = lessonsInUnit.find((lessonInUnit) => lessonInUnit.id === lesson.id);
    if (lessonInStore) {
      lessonInStore.expanded = !lessonInStore.expanded;
    }
  }

  /**
   * @private
   * Insert topics data for given lessons in lessons array
   * @param {Lesson[]} lessonsInStore - Lessons in vocab tools app state
   * @param {Lesson[]} lessonsToAdd - Lessons to add in lessons array
   */
  updateLessonsWithTopics(lessonsInStore, lessonsToAdd) {
    lessonsToAdd.forEach((lessonToAdd) => {
      const lessonInStore = lessonsInStore.find((lesson) => lesson.id === lessonToAdd.id);
      if (lessonInStore) {
        // If 'My Words' is already selected, then make it selected again.
        // This is for usecase when User Word is added before data is fetched for a lesson.
        this.setSelectionOnMyWords(lessonInStore, lessonToAdd);

        lessonInStore.topics = lessonToAdd.topics;
        lessonInStore.expanded = true;
        lessonInStore.selected = true;
      }
    });
  }
}
