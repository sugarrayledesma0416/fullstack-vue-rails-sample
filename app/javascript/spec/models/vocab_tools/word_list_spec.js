import fetchMock from 'fetch-mock';
import * as ajaxUtils from 'shared/ajax_utils';
import Lesson from 'models/vocab_tools/lesson';
import WordList from 'models/vocab_tools/word_list';

VHL = { Audio: {}};
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
};

describe('WordList', () => {
  let lesson;
  const listOfWords = ['word1', 'word2', 'word3'];
  let vocabToolBaseUrl;

  describe('#forLesson', () => {
    afterEach(() => {
      fetchMock.restore();
    });

    describe('when no lesson is specified', () => {
      describe('when the current url has no query params', () => {
        beforeEach(() => {
          vocabToolBaseUrl = 'http://localhost/vocab_tools/words';
          window.history.pushState({}, '', vocabToolBaseUrl);

          /* Mock the fetch call. */
          fetchMock.mock(`${vocabToolBaseUrl}.json`, { status: 200 });
          spyOn(ajaxUtils, 'getFromEndpoint').and.callThrough();
          WordList.forLesson();
        });

        it('requests data from a json endpoint with no query params', () => {
          expect(ajaxUtils.getFromEndpoint).toHaveBeenCalledWith(
            `${vocabToolBaseUrl}.json`, jasmine.any(Function)
          );
        });
      });

      describe('when the current url has a question mark but no params', () => {
        beforeEach(() => {
          vocabToolBaseUrl = 'http://localhost/vocab_tools/words';
          window.history.pushState({}, '', `${vocabToolBaseUrl}?`);

          /* Mock the fetch call. */
          fetchMock.mock(`${vocabToolBaseUrl}.json`, { status: 200, body: {}});
          spyOn(ajaxUtils, 'getFromEndpoint').and.callThrough();
          WordList.forLesson();
        });

        it('requests data from a json endpoint with no query params', () => {
          expect(ajaxUtils.getFromEndpoint).toHaveBeenCalledWith(
            vocabToolBaseUrl + '.json', jasmine.any(Function)
          );
        });
      });

      describe('when the current url has query params', () => {
        beforeEach(() => {
          vocabToolBaseUrl = 'http://localhost/vocab_tools/words';
          window.history.pushState({}, '', `${vocabToolBaseUrl}?unit_id=1234`);

          /* Mock the fetch call. */
          fetchMock.mock(`${vocabToolBaseUrl}.json?unit_id=1234`, { status: 200 });
          spyOn(ajaxUtils, 'getFromEndpoint').and.callThrough();
          WordList.forLesson();
        });

        it('requests data from a json endpoint, passing the same query params', () => {
          expect(ajaxUtils.getFromEndpoint).toHaveBeenCalledWith(
            vocabToolBaseUrl + '.json?unit_id=1234', jasmine.any(Function)
          );
        });
      });
    });

    describe('when word-list factory is given a lesson', () => {
      beforeEach(() => {
        lesson = { id: 'my_id' };
        vocabToolBaseUrl = 'http://localhost/vocab_tools/words';
        window.history.pushState({}, '', vocabToolBaseUrl);

        /* Mock the fetch call. */
        fetchMock.mock(
          `${vocabToolBaseUrl}.json?lesson_id=my_id`,
          { status: 200, body: listOfWords }
        );
        spyOn(ajaxUtils, 'getFromEndpoint').and.callThrough();
      });

      it('requests data from a json endpoint, passing the specified lesson id as' +
         'a query param', () => {
        WordList.forLesson(lesson);
        expect(ajaxUtils.getFromEndpoint).toHaveBeenCalledWith(
          vocabToolBaseUrl + '.json?lesson_id=my_id', jasmine.any(Function)
        );
      });

      it('returns the json retrieved from the endpoint', () => {
        WordList.forLesson(lesson).then(function(response) {
          expect(response).toEqual(listOfWords);
        });
      });
    });
  });

  describe('#organize', () => {
    let arrayOfWords;

    beforeEach(() => {
      arrayOfWords = [
        {
          lesson_id: 1,
          target: 'foo.1.1',
          topic: 'topic 1',
        },
        {
          lesson_id: 1,
          target: 'foo.1.2',
          topic: 'topic 2',
        },
        {
          lesson_id: 2,
          target: 'foo.2.1',
          topic: 'topic 1',
        },
        {
          lesson_id: 2,
          target: 'foo.2.2',
          topic: 'topic 2',
        },
      ];
    });

    it('transforms a flat array of words into an array of Lessons', () => {
      const lesson1Words = [
        { target: 'foo.1.1', lesson_id: 1, topic: 'topic 1' },
        { target: 'foo.1.2', lesson_id: 1, topic: 'topic 2' },
      ];

      const lesson2Words =
      [{ target: 'foo.2.1', lesson_id: 2, topic: 'topic 1' },
        { target: 'foo.2.2', lesson_id: 2, topic: 'topic 2' },
      ];

      expect(WordList.organize(arrayOfWords)).toEqual([
        new Lesson({ id: 1, words: lesson1Words }, false),
        new Lesson({ id: 2, words: lesson2Words }, false),
      ]);
    });
  });
});
