import Word from 'models/vocab_tools/word';

VHL = {
  Audio: {},
  VocabTools: {
    ARTICLES: {
      French: ['le ', 'la ', "l'", 'l’', 'de la ', "de l'", 'de l’'],
      Spanish: ['el ', 'el/la ', 'la ', 'las ', 'las/los'],
    },
    currentTargetLanguage: 'Spanish',
  },
};

VHL.Audio.CollectionScheduler = class CollectionScheduler {
  constructor(paths) {
    this.files = [];
    paths.forEach((path) => {
      this.files.push({ src: path });
    });
  }

  stop_and_reset() {
    jest.fn();
  }

  play_all() {
    jest.fn();
  }
};

describe('Word', () => {
  let word;

  const wordHash = {
    audio_paths: ['http://example.com/my/audio/file.mp3'],
    definition: 'definition of word 1',
    lesson: 'lesson 1',
    target: 'word 1 in spanish',
    topic: 'topic 1',
    translation: 'word 1 in english',
  };

  describe('creating instance', () => {
    beforeEach(() => {
      word = new Word(wordHash);
    });

    it('initializes word with correct lesson name', () => {
      expect(word.lesson).toEqual('lesson 1');
    });

    it('initializes word with correct topic name', () => {
      expect(word.topic).toEqual('topic 1');
    });

    it('initializes word with correct target word', () => {
      expect(word.target).toEqual('word 1 in spanish');
    });

    it('initializes word with correct definition', () => {
      expect(word.definition).toEqual('definition of word 1');
    });

    it('initializes word with correct translation', () => {
      expect(word.translation).toEqual('word 1 in english');
    });
  });

  describe('setAudioFiles', () => {
    beforeEach(() => {
      word = new Word(wordHash);
      word.setAudioFiles();
    });

    it('initializes word with audio files based on links', () => {
      expect(word.audioFiles.files[0].src).toEqual('http://example.com/my/audio/file.mp3');
    });
  });

  describe('#isUserDefined', () => {
    beforeEach(() => {
      word = new Word({ topic: 'topic 1' });
    });

    it('returns true for a user-defined word', () => {
      word.topic = 'My Words';
      expect(word.isUserDefined).toBe(true);
    });

    it('returns false for a VHL-defined word', () => {
      expect(word.isUserDefined).toBe(false);
    });
  });

  describe('#headword', () => {
    beforeEach(() => {
      word = new Word(wordHash);
    });

    it('returns its string unchanged for a word with neither articles nor diacritics ', () => {
      expect(word.headword).toEqual(word.target);
    });

    it('returns its string without the article for a word with an article at the beginning', () => {
      word.target = 'el/la word with ASCII characters only';
      expect(word.headword).toEqual('word with ASCII characters only');
    });

    it('returns its string without the article for a word with a capitalized article at' +
       'the beginning', () => {
      word.target = 'El/la word with ASCII characters only';
      expect(word.headword).toEqual('word with ASCII characters only');
    });

    it('returns the transliteration for a word that includes an ASCII transliteration', () => {
      word.ascii = 'the ASCII transliteration';
      expect(word.headword).toEqual('the ASCII transliteration');
    });

    it('returns the transliteration minus the article for a word with an ASCII transliteration' +
       'that includes an article at the beginning', () => {
      word.ascii = 'el/la ASCII transliteration';
      expect(word.headword).toEqual('ASCII transliteration');
    });

    it('returns its string without that phrase for a word with a parenthesized phrase at' +
       'the beginning', () => {
      word.target = '(ignore this part) actual word';
      expect(word.headword).toEqual('actual word');
    });

    it('returns its string without that phrase for a word with a parenthesized phrase' +
       'in the middle', () => {
      word.target = 'actual (ignore this part) word';
      expect(word.headword).toEqual('actual word');
    });

    it('returns its string without that phrase for a word with a parenthesized phrase' +
       'at the end', () => {
      word.target = 'actual word (ignore this part)';
      expect(word.headword).toEqual('actual word');
    });

    it('returns its string without those phrases for a word with several parenthesized' +
       'phrases', () => {
      word.target = '(ignore this part) actual (ignore this part) word (ignore this part)';
      expect(word.headword).toEqual('actual word');
    });

    it('returns its string without the first character for a word with a question mark at' +
       'the beginning of the first token', () => {
      word.target = '?Y usted?';
      expect(word.headword).toEqual('Y usted?');
    });

    it('returns its string without the first character for a word with an exclamation point at' +
       'the beginning of the first token', () => {
      word.target = '!Viva!';
      expect(word.headword).toEqual('Viva!');
    });

    it('returns its string without the article for a word with an article that is separated from' +
       'the rest of the word by an apostrophe', () => {
      VHL.VocabTools.currentTargetLanguage = 'French';
      word.target = "l'art";
      expect(word.headword).toEqual('art');
    });

    it('returns its string without the article a word with an article that includes a space',
      () => {
        VHL.VocabTools.currentTargetLanguage = 'French';
        word.target = 'de la soul';
        expect(word.headword).toEqual('soul');
      });

    it('returns its string without the article for a word with an article that includes a space' +
       'and is separated from the rest of the word by an apostrophe', () => {
      VHL.VocabTools.currentTargetLanguage = 'French';
      word.target = "de l'art";
      expect(word.headword).toEqual('art');
    });

    it('returns its string without the article for a word with an article that is separated from' +
       'the rest of the word by a right single quote', () => {
      VHL.VocabTools.currentTargetLanguage = 'French';
      word.target = 'l’art';
      expect(word.headword).toEqual('art');
    });

    it(' returns its string without the article for a word with an article that includes a space' +
       'and is separated from the rest of the word by a right single quote', () => {
      VHL.VocabTools.currentTargetLanguage = 'French';
      word.target = 'de l’art';
      expect(word.headword).toEqual('art');
    });
  });

  describe('#hasAudio', () => {
    describe('when audio paths are present', () => {
      beforeEach(() => {
        wordHash.audio_paths = ['http://example.com/my/audio/file.mp3'];
        word = new Word(wordHash);
        word.setAudioFiles();
        word.play();
      });

      it('returns true', () => {
        expect(word.hasAudio).toBeTruthy();
      });
    });

    describe('when the word has no audio paths', () => {
      beforeEach(() => {
        wordHash.audio_paths = [];
        word = new Word(wordHash);
        word.setAudioFiles();
        word.play();
      });

      it('returns false', () => {
        expect(word.hasAudio).toBeFalsy();
      });
    });
  });

  describe('stopPlayback', () => {
    beforeEach(() => {
      wordHash.audio_paths = ['http://example.com/my/audio/file.mp3'];
      word = new Word(wordHash);
      word.setAudioFiles();
      spyOn(word.audioFiles, 'stop_and_reset');
      word.stopPlayback();
    });

    it('stops playing the audio files', () => {
      expect(word.audioFiles.stop_and_reset).toHaveBeenCalled();
    });
  });

  describe('#play', () => {
    describe('when audio files are present', () => {
      beforeEach(() => {
        wordHash.audio_paths = ['http://example.com/my/audio/file.mp3'];
        word = new Word(wordHash);
        word.setAudioFiles();
        spyOn(word.audioFiles, 'play_all');
        word.play();
      });

      it('plays the audio files if there are any', () => {
        expect(word.audioFiles.play_all).toHaveBeenCalled();
      });
    });

    describe('when audio files are not present', () => {
      beforeEach(() => {
        wordHash.audio_paths = [];
        word = new Word(wordHash);
        word.setAudioFiles();
        spyOn(word.audioFiles, 'play_all');
        word.play();
      });

      it('plays the audio files if there are any', () => {
        expect(word.audioFiles.play_all).not.toHaveBeenCalled();
      });
    });
  });
});
