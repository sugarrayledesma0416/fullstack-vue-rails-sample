import Word from './word';
/**
 * Class representing Unit.
 */
class Topic {
  /**
   * Instantiate the Topic class.
   * @param {Object} topic - Topic for vocab tools.
   * @param {String} topic.name - Name of a topic.
   * @param {Array} topic.words - Array of words associated with topic.
   * @param {Boolean} selected - Whether topic is selected.
   */
  constructor(topic, selected) {
    this.name = topic.name;
    this.words = topic.words;
    this.selected = selected;
    this.createWords();
  }

  /**
   * Gets word count for a topic.
   * @return {Number} - Word count for a topic.
   */
  get wordCount() {
    return this.words.length;
  }

  /**
   * Create words object for a topic.
   */
  createWords() {
    const wordsCopy = this.words.slice();
    this.words = [];
    wordsCopy.forEach((word) => {
      this.addWord(word);
    });
  }

  /**
   * Gets Words corresponding to the topic which are selected.
   * @return {Array} - words corresponding to the topic which are selected.
   */
  get selectedWords() {
    return this.selected ? this.words : [];
  }

  /**
   * Stops Audio.
   */
  stopAudio() {
    this.words.forEach((word) => {
      word.stopPlayback();
    });
  }

  /**
   * Adds a single word to the array of words
   * corresponding to a topic.
   * @param {Object} wordToAdd - Word to add.
   */
  addWord(wordToAdd) {
    if (
      this.words.find((word) => word.target === wordToAdd.target)
    ) {
      return;
    }

    this.words.push(new Word(wordToAdd));
  }

  /**
   * Removes a single word to the array of words
   * corresponding to a topic.
   * @param {Object} wordToRemove - Word to Remove.
   */
  removeWord(wordToRemove) {
    if (this.name !== 'My Words') {
      return;
    }
    let wordIndex = -1;
    this.words.forEach((word, index) => {
      if ( word.target === wordToRemove.target ) {
        wordIndex = index;
      }
    });

    if (wordIndex === -1) return;
    this.words.splice(wordIndex, 1);
  }

  /**
   * Gets whether words specific to the topic is empty or not.
   * @return {Boolean} - Returns if topic's words are empty or not.
   */
  get isEmpty() {
    return this.words.length === 0;
  }
}

export default Topic;
