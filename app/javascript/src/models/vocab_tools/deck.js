/** Class representing Deck */
class Deck {
  /**
   * Initialize a deck.
   *
   * @param {(Array|Object)} data An array of Units | Words object
   * @param {String} type units | words
   */
  constructor(data, type = 'words') {
    if (type === 'words') {
      this.allWords = data;
    } else {
      this.units = data;
      this.allWords = this.selectedWords();
    }
    this.setCards(this.allWords);
  }

  /**
   * Gets all selected words from an array of units.
   *
   * @return {Array} array of Word objects
   */
  selectedWords() {
    return this.units.flatMap((unit) => unit.selectedWords());
  }

  /**
   * Compare two arrays for equality.
   *
   * @param {Array} array1
   * @param {Array} array2
   * @return {Boolean}
   */
  arrayEquals(array1, array2) {
    return JSON.stringify(array1) === JSON.stringify(array2);
  }

  /**
   * Shuffles an array.
   *
   * @param {Array} array
   * @return {Array} Shuffled Array
   */
  shuffleArray(array) {
    for (let i = array.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [array[i], array[j]] = [array[j], array[i]];
    }

    return array;
  }

  /**
   * Shuffles array of Words.
   *
   * For an empty or 1-word array, returns the array as is.
   * Otherwise, guarantees that the order is changed.
   *
   * @param {Array} words An array of Words objects
   * @return {Array} Shuffled Array of Words objects
   */
  shuffle(words) {
    let shuffleWords = words.slice();
    if (words.length > 1) {
      // Shuffle the words until they are not in the original order
      while (this.arrayEquals(shuffleWords, words)) {
        shuffleWords = this.shuffleArray(shuffleWords);
      }
    }
    return shuffleWords;
  }


  /**
   * Creates, shuffles and assigns flashcards based on given words.
   *
   * @param {Array} words array of words from which to make flashcards
   */
  setCards(words) {
    const arrayOfIndexes = Array.from(Array(words.length).keys());
    const shuffledIndexes = this.shuffle(arrayOfIndexes);
    this.flashcards = words.map((word, index) => {
      return { knewIt: undefined, word, shuffledIndex: shuffledIndexes[index] };
    });
  }

  /**
   * Restarts the deck.
   *
   * Student may opt to review only the "didn't know" words.
   *
   * @param {Boolean} [allCards=true] Flag indicating whether to review all cards.
   */
  reinitialize(allCards) {
    // set cards to the didn't-know subset if requested;
    // otherwise, initialize the deck again using the original input words
    if (allCards) {
      this.setCards(this.allWords);
    } else {
      this.setCards(this.didNotKnowItWords);
    }
  }


  /**
   * Returns an array of the flashcards for the words the student did not know.
   *
   * @return {Array} The "didn't know" flashcards
   */
  get didNotKnowItWords() {
    return this.flashcards
      .filter((flashcard) => !flashcard.knewIt)
      .map((flashcard) => flashcard.word);
  }

  /**
   * Returns count of cards the user knew.
   *
   * @return {Number} count of "knew-it" cards
   */
  get knewItCount() {
    return this.flashcards.length - this.didNotKnowItWords.length;
  }


  /**
   * Returns percentage of cards the user knew.
   *
   * @return {Number} percentage of "knew-it" cards
   */
  get knewItPercentage() {
    return this.knewItCount * 100 / this.flashcards.length;
  }

  /**
   * Returns text to be displayed on donut.
   *
   * @return {String}
   */
  get donutText() {
    return `${this.knewItPercentage} <small>%</small>`;
  }

  /**
   * stopAllAudio.
   *
   */
  stopAllAudio() {
    this.allWords.forEach((word) => {
      word.stopPlayback();
    });
  }
}

export default Deck;
