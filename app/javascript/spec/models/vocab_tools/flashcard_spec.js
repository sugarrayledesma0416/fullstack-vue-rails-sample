import { elmFromString } from '../../support/utils';
import Flashcard from 'models/vocab_tools/flashcard';

const audioIconElm = {
  value: elmFromString(`
    <button type="button"></button>
  `),
};

const flashcardElm = {
  value: elmFromString(`
    <div class="c-flashcard"></div>
  `),
};

let card;
let card1;
let card2;

const localState = {
  card,
  deck: {},
  index: 0,
};

const hasAudio = { value: false };
const isFlipped = { value: true };

const options = {
  audioIconElm,
  flashcardElm,
  localState,
  props: {
    modes: {
      TARGET_TO_TRANSLATION: 0,
      TRANSLATION_TO_TARGET: 1,
      DEFINITION_TO_TARGET: 2,
    },
    mode: 0,
  },
  hasAudio,
  isModeTargetToEnglish: { value: true },
  isFlipped,
};

describe('Flashcard', () => {
  let flashcard;

  beforeEach(() => {
    card = {
      knewIt: false,
      showFront: true,
      word: {
        audio_paths: [],
        stopPlayback: jest.fn(),
        play: jest.fn(),
        audioFiles: {
          files: [],
        },
      },
    };

    localState.card = card;
    card1 = { ...card };
    card1.shuffledIndex = 1;
    card2 = { ...card };
    card2.shuffledIndex = 0;
    localState.deck = { flashcards: [card1, card2] };
  });

  describe('activateAudioIcon', () => {
    beforeEach(() => {
      flashcard = new Flashcard(options);
    });

    it('activates the audio Icon', () => {
      flashcard.activateAudioIcon();
      expect(audioIconElm.value.classList).toContain('is-active');
    });
  });

  describe('deactivateAudioIcon', () => {
    beforeEach(() => {
      flashcard = new Flashcard(options);
    });

    it('deactivates the audio Icon', () => {
      flashcard.activateAudioIcon();
      flashcard.deactivateAudioIcon();
      expect(audioIconElm.value.classList).not.toContain('is-active');
    });
  });

  describe('stopPlayback', () => {
    beforeEach(() => {
      flashcard = new Flashcard(options);
    });

    it('stops playing the current card audio files', () => {
      flashcard.stopPlayback();
      expect(localState.card.word.stopPlayback).toHaveBeenCalled();
    });
  });

  describe('play', () => {
    it('plays the current card audio files if present.', () => {
      hasAudio.value = true;
      flashcard = new Flashcard(options);
      flashcard.play();
      expect(localState.card.word.play).toHaveBeenCalled();
    });

    it('does not play the current card audio files if not present.', () => {
      card.word.audio_paths = [];
      hasAudio.value = false;
      flashcard = new Flashcard(options);
      flashcard.play();
      expect(localState.card.word.play).not.toHaveBeenCalled();
    });
  });

  describe('flipToBack', () => {
    beforeEach(() => {
      card.showFront = true;
      isFlipped.value = false;
      flashcard = new Flashcard(options);
    });

    it('stops playing the current card audio files.', () => {
      flashcard.flipToBack();
      expect(localState.card.word.stopPlayback).toHaveBeenCalled();
    });

    it('flips the current card.', () => {
      flashcard.flipToBack();
      expect(card.showFront).toBeFalsy();
    });
  });

  describe('moveToNextCard', () => {
    beforeEach(() => {
      localState.index = 0;
      flashcard = new Flashcard(options);
      flashcard.resetAudioFiles();
    });

    it('increments index by 1.', () => {
      flashcard.moveToNextCard();
      expect(localState.index).toBe(1);
    });

    it('shows the card front.', () => {
      flashcard.moveToNextCard();
      expect(card.showFront).toBeTruthy();
    });

    it('sets review mode to true after last card.', () => {
      [1, 2].forEach(() => {
        flashcard.moveToNextCard();
      });
      expect(localState.reviewMode).toBeTruthy();
    });
  });
});
