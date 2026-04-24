/**
 * This composable has methods to act as Adaptor between VocabTools's state
 * and WordTable component.
 * Ie. to generate props from vocabToolsDataStore which stores state
 * in tree of model class in tree hierarchy of VHL.VocabTools.Unit, VHL.VocabTools.Lesson,
 * VHL.VocabTools.Topic, VHL.VocabTools.Word etc.
 * And to handle user actions in WordTable component to update state in vocabToolsDataStore.
 * @param {VocabToolsDataStore} vocabToolsDataStore - With reactive properties
 * which store vocab tools app state
 * @return {Object} - returns object wrapping following methods
 * addUserWord,
 * getWordTableProps,
 * removeUserWord,
 * updateUserWord,
 */
const useWordTableModelAdaptor = (vocabToolsDataStore) => {
  /**
   * Add user word to the list of words corresponding to the specified lesson.
   * @param {Object} payload - Data emitted by NewWord Component when data
   * is added successfully to the Database.
   */
  const addUserWord = (payload) => {
    vocabToolsDataStore.addUserWord(
      payload.unitId,
      payload.word.lesson_id,
      payload.word
    );
  };

  /**
   * Remove user word from the list of words corresponding to the specified lesson.
   * @param {Object} payload - Data emitted by Edit Component when data
   * is removed successfully from the Database.
   */
  const removeUserWord = (payload) => {
    vocabToolsDataStore.removeUserWord(
      payload.unitId,
      payload.lessonId,
      payload.word
    );
  };

  /**
   * Update the contents of user word within the specified unit and lesson.
   * @param {Object} payload - Data emitted by Edit Component when data
   * is updated successfully to the Database.
   */
  const updateUserWord = (payload) => {
    vocabToolsDataStore.updateUserWord(
      payload.unitId,
      payload.lessonId,
      payload.word
    );
  };

  /**
   * Generate an Object containing props for WordTable component
   * from vocabToolsDataStore which stores state in tree of model class in tree hierarchy of
   * Unit, Lesson, Topic, Word etc
   * @return {Object} - object containing props for WordTable component
   */
  const getWordTableProps = () => {
    return {
      isTranslationHidden: vocabToolsDataStore.isTranslationHidden,
      ssjrStudent: vocabToolsDataStore.ssjrStudent,
      targetLanguage: vocabToolsDataStore.targetLanguage,
      targetLanguageCode: vocabToolsDataStore.targetLanguageCode,
      units: vocabToolsDataStore.units?.map(getPropsForUnit) ?? [],
      viewAllLessons: vocabToolsDataStore.viewAllLessons,
      vocabHasDefinition: vocabToolsDataStore.vocabHasDefinition,
    };
  };

  /**
   * @private
   * Generate an Object containing props for a unit for WordTable component
   * @param {Unit} unit
   * @return {Object}
   */
  const getPropsForUnit = (unit) => {
    return {
      id: unit.id,
      inCourse: unit.inCourse,
      lessons: unit.lessons?.map(getPropsForLesson),
    };
  };

  /**
   * @private
   * Generate an Object containing props for a lesson for WordTable component
   * @param {Lesson} lesson
   * @return {Object}
   */
  const getPropsForLesson = (lesson) => {
    return {
      id: lesson.id,
      inCourse: lesson.inCourse,
      name: lesson.name,
      selectedWords: lesson.selectedWords()?.map(getPropsForWord),
    };
  };

  /**
   * @private
   * Generate an Object containing Vue props for a word passed into a WordTable component
   * @param {Word} word
   * @return {Object}
   */
  const getPropsForWord = (word) => {
    return {
      ascii: word.ascii,
      audio_paths: word.audio_paths,
      definition: word.definition,
      headword: word.headword,
      id: word.id,
      lesson_id: word.lesson_id,
      pinyin: word.pinyin,
      target: word.target,
      topic: word.topic,
      translation: word.translation,
    };
  };

  return {
    addUserWord,
    getWordTableProps,
    removeUserWord,
    updateUserWord,
  };
};

export default useWordTableModelAdaptor;
