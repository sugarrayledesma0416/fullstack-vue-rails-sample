/** Class representing Flashcard */
class Flashcard {
  /**
   * Set up the configutation required for initializing flashcard.
   * @param {object} options
   * @param {object} options.localState - localState variables of the Flashcard component.
   * @param {object} options.props - props received by the Flashcard component.
   * @param {Number} options.props.mode - current selected mode for flashcard.
   * @param {Number} options.props.modes - all possible modes of flashcard.
   * @param {object} options.audioIconElm - vue ref to the audio Icon Element.
   * @param {object} options.flashcardElm - vue ref to the flashcard Element.
   * @param {object} options.hasAudio - computed property determing whether card has audio.
   * @param {object} options.isFlipped - computed property determing whether card is flipped.
   */
  constructor(options) {
    this.localState = options.localState;
    this.props = options.props;
    this.audioIconElm = options.audioIconElm;
    this.flashcardElm = options.flashcardElm;
    this.hasAudio = options.hasAudio;
    this.isFlipped = options.isFlipped;
    this.mode = this.getMode();
  }


  /**
   * Get the current Mode value
   * @return {String}
   */
  getMode() {
    return Object.keys(this.props.modes).find((key) =>
      this.props.modes[key] === this.props.mode
    );
  }

  /**
   * Get whether current mode is 'TARGET_TO_TRANSLATION'
   */
  get isModeTargetToTranslation() {
    return this.mode === 'TARGET_TO_TRANSLATION';
  }

  /**
   * Get whether current mode is 'TRANSLATION_TO_TARGET'
   */
  get isModeTranslationToTarget() {
    return this.mode === 'TRANSLATION_TO_TARGET';
  }

  /**
   * Get whether current mode is 'DEFINITION_TO_TARGET'
   */
  get isModeDefinitionToTarget() {
    return this.mode === 'DEFINITION_TO_TARGET';
  }

  /**
   * Get whether current mode is 'TARGET_TO_DEFINITION'
   */
  get isModeTargetToDefinition() {
    return this.mode === 'TARGET_TO_DEFINITION';
  }

  /**
   * Get whether source language in mode is 'TARGET'
   */
  get isSourceLangTarget() {
    return ['TARGET_TO_TRANSLATION', 'TARGET_TO_DEFINITION'].includes(this.mode);
  }

  /**
   * Activate(highlight) the audio icon.
   */
  activateAudioIcon() {
    this.audioIconElm.value?.classList.add('is-active');
  }

  /**
   * Deactivate(unhighlight) the audio icon.
   */
  deactivateAudioIcon() {
    this.audioIconElm.value?.classList.remove('is-active');
  }

  /**
   * Add event listener from the the audio icon.
   */
  addAudioEventListeners() {
    this.audioFiles.files.forEach((elm) => {
      elm.audio.addEventListener('playing', () => {
        this.activateAudioIcon();
      });
      elm.audio.addEventListener('ended', () => {
        this.deactivateAudioIcon();
      });
      elm.audio.addEventListener('pause', () => {
        this.deactivateAudioIcon();
      });
    });
  }

  /**
   * Remove event listener from the the audio icon.
   */
  removeAudioEventListeners() {
    this.audioFiles.files.forEach((elm) => {
      elm.audio.removeEventListener('playing', () => {
        this.activateAudioIcon();
      });
      elm.audio.removeEventListener('ended', () => {
        this.deactivateAudioIcon();
      });
      elm.audio.removeEventListener('pause', () => {
        this.deactivateAudioIcon();
      });
    });
  }

  /**
   * Reset the audio files (on audio path / elm change).
   */
  resetAudioFiles() {
    const word = this.localState.card.word;
    if (!word.audioFiles) {
      word.setAudioFiles();
    }

    this.audioFiles = this.localState.card.word.audioFiles;
    this.addAudioEventListeners();
  }

  /**
   * Get the current Flashcard value
   */
  get currentFlashCard() {
    return this.localState.deck.flashcards.find(
      (card) => card.shuffledIndex === this.localState.index
    );
  }

  /**
   * Set the current Flashcard value
   * @param {object} card current localstate card
   */
  set currentFlashCard(card) {
    const flashcards = this.localState.deck.flashcards;
    const index = flashcards.indexOf(this.currentFlashCard);
    flashcards[index] = card;
  }


  /**
   * Reset the card.
   */
  resetCard() {
    this.localState.card.word = this.currentFlashCard.word;
    this.localState.card.shuffledIndex = this.currentFlashCard.shuffledIndex;
    this.localState.card.showFront = true;
    this.localState.card.knewIt = undefined;
  }

  /**
   * Stop the audio from playing.
   */
  stopPlayback() {
    this.localState.card.word.stopPlayback();
  }

  /**
   * Play the card audio.
   */
  play() {
    this.stopPlayback();
    if (this.hasAudio.value) {
      this.localState.card.word.play();
    }
  }

  /**
   * Flip the card to back.
   */
  flipToBack() {
    if (this.isSourceLangTarget) this.stopPlayback();
    this.localState.card.showFront = false;
    if (this.flashcardElm.value) this.flashcardElm.value.focus();
  }

  /**
   * Flip the card and reset audio files.
   */
  flip() {
    if (!this.isFlipped.value) {
      this.flipToBack();
      this.removeAudioEventListeners();
      this.resetAudioFiles();
    }
  }

  /**
   * Move to Next Card.
   * @param {object} option knewIt / not_yet
   */
  moveToNextCard(option) {
    if (this.isSourceLangTarget) this.stopPlayback();
    this.localState.card.knewIt = option === 'knewIt';
    this.currentFlashCard = { ...this.localState.card };
    this.localState.index++;
    this.removeAudioEventListeners();
    if (this.localState.index < this.localState.deck.flashcards.length) {
      this.resetCard();
      this.resetAudioFiles();
    } else {
      this.localState.reviewMode = true;
    }
  }

  /**
   * Restarts the deck.
   * Student may opt to review only the "didn't know" words.
   *
   * @param {Boolean} [allWords=true] Flag indicating whether to review all cards.
   */
  review(allWords = true) {
    this.localState.deck.reinitialize(allWords);
    this.localState.index = 0;
    this.resetCard();
    this.resetAudioFiles();
    this.localState.reviewMode = false;
  }
}

export default Flashcard;
