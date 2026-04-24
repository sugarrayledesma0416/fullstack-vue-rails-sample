/**
 * This composable has methods related to wordlist in the WordTable component.
 * @return {Object} - returns object wrapping following methods
 * hasSelectedWords,
 * orderByHeadword,
 */
const useWordList = () => {
  /** Method returns whether the lesson has selected words
   * @param {Object} lesson -
   * @param {Object[]} lesson.selectedWords - array of selected word objects
   * @return {Boolean} whether the lesson has selected words
   */
  const hasSelectedWords = (lesson) => {
    return lesson?.selectedWords?.length > 0;
  };

  /** Method returns words ordered by word's headword property
   * @param {Object[]} words - array of word objects
   * @param {String} words[].headword - word's headword value used for sorting
   * @return {Object[]} sorted array of words
   */
  const orderByHeadword = (words) => {
    return words.sort((wordA, wordB) => {
      const aHeadWord = wordA.headword.toLowerCase();
      const bHeadWord = wordB.headword.toLowerCase();
      if (aHeadWord < bHeadWord) return -1;
      if (aHeadWord > bHeadWord) return 1;
      return 0;
    });
  };

  return { hasSelectedWords, orderByHeadword };
};

export default useWordList;
