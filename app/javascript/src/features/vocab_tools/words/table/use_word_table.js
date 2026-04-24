import { computed } from 'vue';

/**
 * This composable has methods related to the WordTable component.
 * @param {Int} lessonIdForAddWord - Reactive ref wrapping lessonId for AddWord
 * @param {Object} props - Vue props for Word Table component
 * @param {Object} wordInEdit - Reactive object wrapping information for the word in edit mode
 * @return {Object} - returns object wrapping following methods
 * lessonsWithUnitInfo,
 * resetLessonIdForAddWord,
 * resetWordInEdit
 * setWordInEdit
 * totalColumns
 * updateLessonIdForAddWord
 */
const useWordTable = (lessonIdForAddWord, props, wordInEdit) => {
  /**
    * A program normally has 3 columns:
    * target, translation, and controls (e.g. save button)
    * A program that has definitions has an additional definition column.
    * English programs (that have no translation) have only 3.
    * Chinese programs have one extra "pinyin" column.
    */
  const totalColumns = computed(() => {
    // Early return for English programs, or any future programs that
    // have no translation.
    if (props.isTranslationHidden) return 3;
    let columns = (props.targetLanguageCode === 'zh' ? 4 : 3);
    if (props.vocabHasDefinition) columns++;
    return columns;
  });

  /**
    * This returns flatten lessons array with unit info from units props
    * @return {Array.<{lesson: Object, unit: Object}>} - array with lesson and unit info
    */
  const lessonsWithUnitInfo = computed(() => {
    const filteredUnits = props.units.filter((unit) => {
      return props.viewAllLessons || unit.inCourse;
    });
    return filteredUnits.flatMap((unit) => {
      return unit.lessons.map((lesson) => {
        return { lesson, unit: { id: unit.id }};
      });
    });
  });

  const updateLessonIdForAddWord = ({ lesson }) => {
    lessonIdForAddWord.value = lesson.id;
    if (wordInEdit.word) {
      wordInEdit.word.isEditMode = false;
      wordInEdit.word.accentBarComponent?.deactivateAll();
      wordInEdit.word = null;
    }
  };

  const resetLessonIdForAddWord = () => {
    lessonIdForAddWord.value = null;
  };

  /**
    * Method clears editmode for any exiting word in edit mode then stores new word
    * @param {Object} word - word object for the word which is being edited
    */
  const setWordInEdit = (word) => {
    if (wordInEdit.word) {
      wordInEdit.word.isEditMode = false;
      wordInEdit.word.accentBarComponent?.deactivateAll();
    }
    wordInEdit.word = word;
    lessonIdForAddWord.value = null;
  };

  const resetWordInEdit = () => {
    wordInEdit.word = null;
  };

  return {
    lessonsWithUnitInfo,
    resetLessonIdForAddWord,
    resetWordInEdit,
    setWordInEdit,
    totalColumns,
    updateLessonIdForAddWord,
  };
};

export default useWordTable;
