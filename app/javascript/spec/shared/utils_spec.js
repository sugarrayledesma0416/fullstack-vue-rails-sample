import {
  cloneObject,
  firstInArray,
  getSearchParam,
  groupBy,
  isEmpty,
  omit,
  pluck,
  hasHtml,
  hasKeyInObject,
  htmlToPlainText,
  humanize,
  isFunction,
  isValidExternalUrl,
  lastInArray,
  maxInArray,
  processChineseText,
  reduceObject,
  scrollToTopOfPage,
  setImageMedia,
  sort,
  sortByFunction,
  stripTags,
  sum,
  toSentence,
  union,
  unique,
  uniqueWithFunction,
} from 'shared/utils';
import { testClass } from 'music';

window.scrollTo = jest.fn();

describe('utils', () => {
  describe(
    'cloneObject',
    () => {
      const originalObj = { a: { b: { c: 1 }}};

      it(
        'returns a deep copy of an object',
        () => {
          const clone = cloneObject(originalObj);

          // same contents
          expect(clone).toEqual(originalObj);

          // different identity
          expect(Object.is(clone, originalObj)).toBe(false);
        }
      );

      it(
        'does not preserve any references to source object properties in the copy',
        () => {
          const clone = cloneObject(originalObj);

          clone.a.b.c = 2;
          expect(originalObj.a.b.c).toBe(1);
        }
      );
    }
  );

  describe('getSearchParam', () => {
    it('returns the value associated with the key', () => {
      expect(getSearchParam('?school_id=106', 'school_id')).toEqual('106');
    });
  });

  describe('groupBy', () => {
    let grouped;
    const words = [
      {
        id: 172743,
        target: 'tesé',
        topic: 'My Words',

      },
      {
        id: 172744,
        target: 'andar en patineta',
        topic: 'Pasatiempos',
      },
    ];

    beforeEach(() => {
      grouped = groupBy(words, 'topic');
    });

    it('returns all keys of grouped object', () => {
      expect(Object.keys(grouped)).toEqual(['My Words', 'Pasatiempos']);
    });

    it('returns value with key "My Words"', () => {
      expect(grouped['Pasatiempos']).toEqual(
        [{ id: 172744, target: 'andar en patineta', topic: 'Pasatiempos' }]
      );
    });

    it('returns value with key "Pasatiempos"', () => {
      expect(grouped['My Words']).toEqual(
        [{ id: 172743, target: 'tesé', topic: 'My Words' }]
      );
    });
  });

  describe('hasHtml', () => {
    let wrapperElm;

    beforeEach(() => {
      wrapperElm = document.createElement('div');
    });

    it('returns false if the specified element has only text children', () => {
      wrapperElm.innerHTML = 'a b c d';

      expect(hasHtml(wrapperElm)).toBeFalsy();
    });

    it('returns true if the specified element has any html children', () => {
      wrapperElm.innerHTML = 'a <b> c d';

      expect(hasHtml(wrapperElm)).toBeTruthy();
    });
  });


  describe('hasKeyInObject', () => {
    it('returns true if key is a direct property of an object', () => {
      const obj = {
        key1: 'some value 1',
        key2: 'some value 2',
      };
      const key = 'key1';
      expect(hasKeyInObject(obj, key)).toBe(true);
    });

    it('returns false if key is not a direct property of an object', () => {
      const obj = {
        kay1: 'some value 1',
        kay2: 'some value 2',
      };
      const key = 'key3';
      expect(hasKeyInObject(obj, key)).toBe(false);
    });

    it('returns false if object is falsy e.g. null, undefined etc', () => {
      const obj = null;
      const key = 'key1';
      expect(hasKeyInObject(obj, key)).toBe(false);
    });
  });

  describe('htmlToPlainText', () => {
    it('converts html string to plain text', () => {
      expect(htmlToPlainText('<h1>Foo</h1><br/><ul>áßðfghïœø</ul>')).toBe('Fooáßðfghïœø');
      expect(htmlToPlainText('<h1></h1><br/><ul></ul>')).toBe('');
      expect(htmlToPlainText('')).toBe('');
    });
  });

  describe('humanize', () => {
    it('returns string in human readable format', () => {
      expect(humanize('foo bar baz')).toBe('Foo bar baz');
      expect(humanize('foo_bar_baz')).toBe('Foo bar baz');
      expect(humanize('fooBarBaz')).toBe('FooBarBaz');
    });
  });

  describe('isEmpty', () => {
    describe('when string is empty', () => {
      it('returns true if string is empty', () => {
        expect(isEmpty('')).toBeTruthy();
      });

      it('returns true if string contains only whitespace', () => {
        expect(isEmpty('  ')).toBeTruthy();
      });
    });

    it('returns false if string is not empty', () => {
      expect(isEmpty('not empty')).toBeFalsy();
    });
  });

  describe('isFunction', () => {
    it('returns true for a function argument', () => {
      const funVar = () => {};
      expect(isFunction(funVar)).toBe(true);
    });

    it('returns false for a non-function argument', () => {
      const nonFunVar = {};
      expect(isFunction(nonFunVar)).toBe(false);
    });
  });

  describe('isValidExternalUrl', () => {
    it('returns true for a valid external link url', () => {
      const acceptedUrls = [
        'http://a.co',
        'http://abc.com',
        'https://abc.com',
        'http://abc-d.ef.gh:1234',
        'https://abc-d.ef.gh:1234/abc=def123',
      ];
      const validityCheckArr = acceptedUrls.map(
        (url) => isValidExternalUrl(url)
      );
      expect(validityCheckArr).toEqual([
        true,
        true,
        true,
        true,
        true,
      ]);
    });

    it('returns false for an external link url which is in non-accepted format', () => {
      const notAcceptedUrls = [
        undefined,
        'www.abc.com',
        'ftp://abc.com',
        'http://abc.com:12ab',
        'otherthanhttp://abc.com',
        'http://-abc.com',
      ];
      const validityCheckArr = notAcceptedUrls.map(
        (url) => isValidExternalUrl(url)
      );
      expect(validityCheckArr).toEqual([
        false,
        false,
        false,
        false,
        false,
        false,
      ]);
    });
  });

  describe('omit', () => {
    const obj = {
      id: 172743,
      target: 'tesé',
      topic: 'My Words',
    };

    it('returns object without the given properties to be omitted', () => {
      expect(omit(['id'], obj)).toEqual({
        target: 'tesé',
        topic: 'My Words',
      });
      expect(omit(['id', 'target'], obj)).toEqual({
        topic: 'My Words',
      });
    });

    it('returns empty object if given object is undefined', () => {
      expect(omit(['id', 'target'], undefined)).toEqual({});
    });
  });

  describe('pluck', () => {
    const arr = [
      {
        id: 172743,
        target: 'tesé',
        topic: 'My Words',
      },
      {
        id: 172744,
        target: 'andar en patineta',
        topic: 'Pasatiempos',
      },
    ];

    it('returns a list of given property values from array of objects', () => {
      expect(pluck(arr, 'id')).toEqual([172743, 172744]);
      expect(pluck(arr, 'topic')).toEqual(['My Words', 'Pasatiempos']);
    });
  });

  describe('firstInArray', () => {
    it('returns first element of the array', () => {
      const arr = ['a', 'b', 'c'];
      expect(firstInArray(arr)).toEqual('a');
    });

    it('returns first element of the array of objects', () => {
      const arr = [{ id: 'a' }, { id: 'b' }, { id: 'c' }];
      expect(firstInArray(arr)).toEqual({ id: 'a' });
    });

    it('returns undefined if given array is undefined', () => {
      expect(firstInArray(undefined)).toEqual(undefined);
    });
  });

  describe('lastInArray', () => {
    it('returns last element of the array', () => {
      const arr = ['a', 'b', 'c'];
      expect(lastInArray(arr)).toEqual('c');
    });

    it('returns last element of the array of objects', () => {
      const arr = [{ id: 'a' }, { id: 'b' }, { id: 'c' }];
      expect(lastInArray(arr)).toEqual({ id: 'c' });
    });

    it('returns undefined if given array is undefined', () => {
      expect(lastInArray(undefined)).toEqual(undefined);
    });
  });

  describe('maxInArray', () => {
    it('returns max element of the array', () => {
      const arr = [1, 4, 3];
      expect(maxInArray(arr)).toEqual(4);
    });

    it('returns element of the array of objects corresponding to ' +
      'maximum value of the given iteratee function', () => {
      const arr = [
        { id: 'a', iterateeKey: 1 },
        { id: 'b', iterateeKey: 4 },
        { id: 'c', iterateeKey: 3 },
      ];
      function iteratee(item) {
        return item.iterateeKey;
      }
      expect(maxInArray(arr, iteratee)).toEqual({ id: 'b', iterateeKey: 4 });
    });

    it('returns undefined if given array is empty', () => {
      expect(maxInArray([])).toEqual(undefined);
    });

    it('returns undefined if given array is undefined', () => {
      expect(maxInArray(undefined)).toEqual(undefined);
    });
  });

  describe('sum', () => {
    it('returns sum of numbers in the array', () => {
      expect(sum([1, 2, 4, 5, 7])).toBe(19);
      expect(sum([1, 2, 4, 5, 6])).toBe(18);
    });
  });

  describe('testClass', () => {
    const OLD_ENV = process.env;

    beforeEach(() => {
      jest.resetModules();
      process.env = { ...OLD_ENV };
    });

    afterAll(() => {
      process.env = OLD_ENV;
    });

    it('returns an empty string if neither Node nor Rails env is test', () => {
      process.env.NODE_ENV = 'dev';
      process.env.RAILS_ENV = 'development';
      expect(testClass('foo')).toEqual('');
    });

    it('returns "test-[ARG]" if Node env is test', () => {
      process.env.RAILS_ENV = 'development';
      expect(testClass('foo')).toEqual('test-foo');
    });

    it('returns "test-[ARG]" if Rails env is test', () => {
      process.env.NODE_ENV = 'dev';
      process.env.RAILS_ENV = 'test';
      expect(testClass('foo')).toEqual('test-foo');
    });
  });

  describe('unique', () => {
    it('returns duplicate-free version of the array', () => {
      expect(unique([1, 1, 2, 'a', 'a', 'b'])).toEqual([1, 2, 'a', 'b']);
    });
  });

  describe('reduceObject', () => {
    it('returns reduced value for an object based on reducer function which sums all values',
      () => {
        const reducerFnToSumAllValues = (memo, currentValue, currentKey, obj) => {
          memo = memo + currentValue;
          return memo;
        };
        const objToBeReduced = {
          'key1': 10,
          'key2': 20,
          'key3': 30,
        };
        expect(reduceObject(objToBeReduced, 0, reducerFnToSumAllValues)).toBe(60);
      }
    );

    it('returns reduced value for an object based on reducer function which counts occurrences',
      () => {
        const reducerFnToCountOccurrence = (memo, currentValue, currentKey, obj) => {
          for (let i = 0; i < currentValue.length; i++) {
            const currentNumber = currentValue[i];
            if (memo[currentNumber]) {
              memo[currentNumber] = memo[currentNumber] + 1;
            } else {
              memo[currentNumber] = 1;
            }
          }
          return memo;
        };
        const objToBeReduced = {
          'key1': [10, 20, 30],
          'key2': [20, 40, 60],
          'key3': [30, 60, 90],
        };
        const expectedObject = {
          10: 1,
          20: 2,
          30: 2,
          40: 1,
          60: 2,
          90: 1,
        };
        expect(
          reduceObject(objToBeReduced, {}, reducerFnToCountOccurrence)
        ).toEqual(expectedObject);
      }
    );
  });

  describe('scrollToTopOfPage', () => {
    it('Scrolls to the top of the page', () => {
      const spy = jest.spyOn(window, 'scrollTo');
      scrollToTopOfPage();
      expect(spy).toHaveBeenCalledWith(0, 0);
    });
  });

  describe('setImageMedia', () => {
    let parentDiv;
    let oldElm;

    const mediaLookup = {
      123: { src: '/path/to/123' },
      234: { src: '/path/to/234' },
    };

    beforeEach(() => {
      parentDiv = document.createElement('div');
      oldElm = document.createElement('img');
      parentDiv.append(oldElm);
    });

    it('does not alter images with no id attribute', () => {
      setImageMedia(oldElm, mediaLookup);

      expect(parentDiv.innerHTML).toEqual('<img>');
    });

    it('does not alter images with an id not found in the mediaLookup', () => {
      oldElm.id = 555;
      setImageMedia(oldElm, mediaLookup);

      expect(parentDiv.innerHTML).toEqual('<img id="555">');
    });

    it('it replaces images with an id found in the mediaLookup with an ' +
       'image with the src set to the path from the mediaLookup for that id', () => {
      oldElm.id = 234;
      setImageMedia(oldElm, mediaLookup);

      expect(parentDiv.innerHTML).toEqual('<img src="/path/to/234">');
    });
  });

  describe('sort', () => {
    const arr = [
      { first_name: 'Elise', last_name: 'Herzog' },
      { first_name: 'Zona', last_name: 'Fahey' },
      { first_name: 'Rosalind', last_name: 'Dorgan' },
    ];
    let sortedArray;
    describe('when type is asc', () => {
      describe('when key is first_name', () => {
        it('returns array sorted by first_name', () => {
          sortedArray = sort(arr, 'first_name', 'asc');
          expect(sortedArray.map((elm) => elm.first_name)).toEqual(
            ['Elise', 'Rosalind', 'Zona']
          );
        });
      });

      describe('when key is last_name', () => {
        it('returns array sorted by last_name', () => {
          sortedArray = sort(arr, 'last_name', 'asc');
          expect(sortedArray.map((elm) => elm.last_name)).toEqual(
            ['Dorgan', 'Fahey', 'Herzog']
          );
        });
      });
    });

    describe('when type is desc', () => {
      describe('when key is first_name', () => {
        it('returns array sorted by first_name in descending order', () => {
          sortedArray = sort(arr, 'first_name', 'desc');
          expect(sortedArray.map((elm) => elm.first_name)).toEqual(
            ['Zona', 'Rosalind', 'Elise']
          );
        });
      });

      describe('when key is last_name', () => {
        it('returns array sorted by last_name in descending order', () => {
          sortedArray = sort(arr, 'last_name', 'desc');
          expect(sortedArray.map((elm) => elm.last_name)).toEqual(
            ['Herzog', 'Fahey', 'Dorgan']
          );
        });
      });
    });
  });

  describe('sortByFunction', () => {
    it('returns sorted array using provided function', () => {
      const transformationFn = (item) => {
        return item.propertyForSort;
      };
      const arrToBeSorted = [
        { propertyForSort: 1, otherKey: 'A' },
        { propertyForSort: 3, otherKey: 'B' },
        { propertyForSort: 2, otherKey: 'C' },
      ];
      const expectedSortedArr = [
        { propertyForSort: 1, otherKey: 'A' },
        { propertyForSort: 2, otherKey: 'C' },
        { propertyForSort: 3, otherKey: 'B' },
      ];
      expect(sortByFunction(arrToBeSorted, transformationFn)).toEqual(expectedSortedArr);
    });
  });

  describe('stripTags', () => {
    it('returns text that stripped out any html tags', () => {
      const htmlText = '<html>ABC</html>';
      expect(stripTags(htmlText)).toEqual('ABC');
    });
  });

  describe('sum', () => {
    it('returns sum of numbers in the array', () => {
      expect(sum([1, 2, 4, 5, 7])).toBe(19);
      expect(sum([1, 2, 4, 5, 6])).toBe(18);
    });
  });

  describe('toSentence', () => {
    it('Joins an array with "and" and commas', () => {
      expect(toSentence(['one', 'two', 'three'])).toEqual('one, two and three');
      expect(toSentence(['one', 'two'])).toEqual('one and two');
    });
  });

  describe('union', () => {
    it('returns union of arrays for string arrays', () => {
      const arr1 = ['A', 'B', 'C'];
      const arr2 = ['A', 'B', 'D'];
      const expectedUnionArr = ['A', 'B', 'C', 'D'];
      expect(union(arr1, arr2)).toEqual(expectedUnionArr);
    });
  });

  describe('unique', () => {
    it('returns array with unique values for string arrays', () => {
      const arr = ['A', 'B', 'C', 'B', 'D', 'C'];
      const expectedUniqueArr = ['A', 'B', 'C', 'D'];
      expect(unique(arr)).toEqual(expectedUniqueArr);
    });
  });

  describe('uniqueWithFunction', () => {
    it('returns array with unique values using provided function', () => {
      const transformationFn = (item) => {
        return item.someKey;
      };
      const arr = [
        { someKey: 'A' },
        { someKey: 'B' },
        { someKey: 'C' },
        { someKey: 'B' },
        { someKey: 'D' },
        { someKey: 'C' },
      ];
      const expectedUniqueArr = [
        { someKey: 'A' },
        { someKey: 'B' },
        { someKey: 'C' },
        { someKey: 'D' },
      ];
      expect(uniqueWithFunction(arr, transformationFn)).toEqual(expectedUniqueArr);
    });
  });

  describe('processChineseText', () => {
    it('escapes html tags', () => {
      const user_text = '<script>malicious code</script>';
      expect(processChineseText(user_text)).toEqual(
        '&lt;script&gt;malicious code&lt;/script&gt;'
      );
    });

    it('wraps chinese characters and punctuation in span tags with a lang attribute', () => {
      const user_text = 'Chinese text follows 卒為善士。 1984年  我喜欢芒果、';
      expect(processChineseText(user_text)).toEqual(
        'Chinese text follows <span lang="zh">卒為善士。 1984年  我喜欢芒果、</span>'
      );
    });
  });
});
