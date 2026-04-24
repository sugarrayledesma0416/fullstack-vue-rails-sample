/**
 * Class representing Word.
 */
class Word {
  /**
   * Instantiate the Word class.
   * @param {Object} wordHash - Lesson for vocab tools.
   * @param {Number} wordHash.lesson_id - Id of a Lesson.
   * @param {String} wordHash.target - Name of a target eg 'Hola.'.
   * @param {String} wordHash.topic - Name of a topic eg 'Saludos'.
   */
  constructor(wordHash) {
    /**
     * The body of a for-in should be wrapped in an if statement to filter
     * unwanted properties from the prototype.
     */
    for (const key in wordHash) {
      if (Object.prototype.hasOwnProperty.call(wordHash, key)) {
        this[key] = wordHash[key];
      }
    }
  }

  /**
   * Set audio Files for a word.
   */
  setAudioFiles() {
    this.audioFiles = new VHL.Audio.CollectionScheduler(this.audio_paths || []);
  }

  /**
   * Whether the word has audio files.
   */
  get hasAudio() {
    return this.audioFiles.files.length > 0;
  }

  /**
   * Provides string to sort by
   *
   * @public
   * @return {String} sortable version of word
   */
  get headword() {
    if (this.storedHeadword === undefined) {
      const compose = (...functions) => (args) => functions.reduceRight((arg, fn) => fn(arg), args);

      // Compose the functions to compute the headword
      const headword = compose(
        this.removeInitialArticle,
        this.removeInitialInvertedPunctuation,
        this.removeExtraSpaces,
        this.removeParenthesizedPhrases);
      this.storedHeadword = headword(this.wordAsAscii);
    }
    return this.storedHeadword;
  }

  /**
   * Returns ASCII-only version of word.
   *
   * @return {String} - the ASCII transliteration if it exists, the word as it is otherwise
   */
  get wordAsAscii() {
    return this.ascii || this.target;
  }

  /**
   * Removes any parenthesized phrase from within the stored headword.
   *
   * Example: "(Muy) bien" -> "bien"
   *
   * @param {String} data - The string to be processed
   * @return {String} - The processed string
   */
  removeParenthesizedPhrases(data) {
    const regex = /\([^()]+\)/g;
    return data.replace(regex, '');
  }

  /**
   * Removes extra spaces that may have resulted from removing parens.
   *
   * @param {String} data - The string to be processed
   * @return {String} - The processed string
   */
  removeExtraSpaces(data) {
    const regex = /\s\s/g;
    return data.trim().replace(regex, ' ');
  }

  /**
   *  Removes question marks and exclamation points from the beginning of the stored headword.
   *
   * Note: the punctuation is inverted in the original Spanish target.
   * The server adds an ascii attribute that changes the punctuation
   * to its right-side-up equivalent.
   *
   * Example: "?Y usted?" -> "Y usted?"
   *
   * @param {String} data - The string to be processed
   * @return {String} - The processed string
   */
  removeInitialInvertedPunctuation(data) {
    const regex = /^([?!])(.*)$/;
    return data.replace(regex, '$2');
  }

  /**
   * Removes any article from the beginning of the stored headword
   *
   * Example: "la cosa" -> "cosa"
   *
   * @param {String} data -The string to be processed
   * @return {String} The processed string
   */
  removeInitialArticle(data) {
    const language = VHL.VocabTools.currentTargetLanguage;
    const initialArticle = VHL.VocabTools.ARTICLES[language]?.find((article) => {
      return data.toLowerCase().indexOf(article) === 0;
    });
    return initialArticle === undefined ? data : data.substring(initialArticle.length);
  }

  /**
   * Reports whether the word is user-defined
   *
   * @public
   * @return {Boolean}
   */
  get isUserDefined() {
    return this.topic === 'My Words';
  }

  /**
   * Stop the audio from playing.
   */
  stopPlayback() {
    this.audioFiles?.stop_and_reset();
  }

  /**
   * Play the card audio.
   */
  play() {
    this.stopPlayback();
    if (this.hasAudio) {
      this.audioFiles.play_all({
        callback: () => {},
        when: 'before',
        last_callback: () => {},
      });
    }
  }
}

export default Word;
