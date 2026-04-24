import { escape } from 'underscore';

/**
 * Returns a deep copy of an object that does not preserve any references
 * to object properties or their descendants. Ensures that any mutations
 * to the copy do not affect the source.
 * @param {Object} sourceObj
 * @return {Object} Deep copy of sourceObj with de-referenced properties
 */
const cloneObject = (sourceObj) => {
  return JSON.parse(JSON.stringify(sourceObj));
};

/**
 * This method create a composition of the list of functions.
 * @param {Array} functions - List of functions.
 * @return {Function}
 */
function compose(...functions) {
  return function(args) {
    return functions.reduceRight((arg, fn) => fn(arg), args);
  };
}

/**
 * This method triggers custom event on document
 * @param {Event} evt - Object with format {name: String, detail: Any}
 */
const dispatchCustomEvent = (evt) => {
  const customEvent = new CustomEvent(evt.name, {
    detail: evt.detail,
  });
  document.dispatchEvent(customEvent);
};

/**
 * Return first element of an array
 * @param {Array} arr
 * @return {*}
 */
function firstInArray(arr) {
  return arr?.length ? arr[0] : undefined;
}

/**
 * Returns the value for a key in a query string.
 * @param {string} queryString String of format '?key=value&key2=value2...'
 * @param {string} key The name of the key to be looked up.
 * @return {string} The value associated with the key.
 */
const getSearchParam = (queryString, key) => {
  return new URLSearchParams(queryString).get(key);
};

/**
 * Group items by unique value of a key.
 * @param {Array} list - List containing the items.
 * @param {String} key - The key to be used for grouping.
 * @return {Object}
 */
const groupBy = (list, key) => {
  return list.reduce((acc, value) => {
    // Group initialization
    if (!acc[value[key]]) {
      acc[value[key]] = [];
    }
    // Grouping
    acc[value[key]].push(value);
    return acc;
  }, {});
};

/**
 * @param {Element} wrapperElm
 * @return {boolean} whether the specified wrapperElm has any children
 * that are HTML Elements
 */
function hasHtml(wrapperElm) {
  return Array.from(wrapperElm.childNodes).some(
    (node) => (node.nodeType === Node.ELEMENT_NODE)
  );
}

/**
 * Convert html string to plain text.
 * @param {String} text - Html string.
 * @return {String}
 */
function htmlToPlainText(text) {
  return String(text).replace(/<[^>]+>/gm, '');
}

/**
 * returns string in human readable format.
 * @param {string} str - string to be formatted
 * @return {string}
 */
function humanize(str) {
  return str
    .replace(/^[\s_]+|[\s_]+$/g, '')
    .replace(/[_\s]+/g, ' ')
    .replace(/^[a-z]/, function(m) {
      return m.toUpperCase();
    });
}

/**
 * return a boolean evaluating whether the string is empty
 * (if contains only whitespace is considered empty) or not
 * @param {string} value - The string to evaluated
 * @return {boolean}
 */
const isEmpty = (value) => {
  return (value ?? '').trim() === '';
};

/**
 * This method is to check if the object is empty.
 * @param {Object} obj
 * @return {Object}
 */
function isObjEmpty(obj) {
  return [Object, Array].includes((obj || {}).constructor) && !Object.entries((obj || {})).length;
}

/**
 * Validate external link url.
 * It requires 'http://' or 'https://'
 * It allows hyphen (-) and dot (.) in the url besides
 * alpha-numerical characters in the main url part.
 * Colon (:) followed by upto 5 digits are allowed
 * at the end of the the main url part.
 * All characters are allowed after forward slash (/) after the main url part.
 * @param {string} url - External url value.
 * @return {boolean} - Whether given url is valid.
 */
function isValidExternalUrl(url) {
  if (!url) return false;
  // eslint-disable-next-line no-useless-escape
  const reg = /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/;
  return reg.test(url);
}

/**
 * Return last element of an array
 * @param {Array} arr
 * @return {*}
 */
function lastInArray(arr) {
  return arr?.length ? arr[arr.length -1] : undefined;
}

/**
 * This returns maximum value item in an array.
 * If iteratee function is given then this returns element of the array
 * corresponding to maximum value of the given iteratee function.
 * @template T
 * @param {Array.<T>} arr
 * @param {Function} iteratee
 * @return {T}
 */
function maxInArray(arr, iteratee) {
  if (typeof iteratee !== 'function') {
    iteratee = (item) => item;
  }
  return [...(arr || [])]
    ?.sort((a, b) => iteratee(a) - iteratee(b))
    ?.pop();
}

/**
 * @summary Look up a <meta> tag by name and get its content.
 * This method is copied from VHL.Common.
 *
 * @param {String} name - the value of the tag's `name` attribute
 * @return {String} the value of the tag's `content` attribute
 */
const metaTagContent = (name) => {
  const tagElm = document.querySelector(`meta[name="${name}"]`);

  // If the meta doesn't exist, return a sensible default.
  if (tagElm === null) {
    return undefined;
  }

  return tagElm.getAttribute('content');
};

/**
 * This method omit the keys from the object.
 * @param {Array} keys - List of keys to be omitted
 * @param {Object} obj - Input Object.
 * @return {Object}
 */
function omit(keys, obj) {
  if (obj === null || obj === undefined) {
    return {};
  }
  return Object.fromEntries(
    Object.entries(obj)
      .filter(([k]) => !keys.includes(k))
  );
}

/**
 * Return an object created from a subset of properties of another object.
 * @param {Object} obj - The source object to copy from.
 * @param {...String} keys - A list of properties to copy.
 * @return {Object}
 */
const pick = (obj, ...keys) => {
  return Object.fromEntries(
    Object.entries(obj).filter(([key]) => keys.includes(key))
  );
};

/**
 * Extract a list of property values from array of objects.
 * @param {Array.<Object>} arr - array of objects.
 * @param {string} key - property to be extracted.
 * @return {Array}
 */
function pluck(arr, key) {
  return arr.map((obj) => obj[key]);
}

/**
 * @summary Get the program ID for the page.
 * Looks up the VHL.program_id <meta> tag and gets its value.
 * This method is copied from VHL.Common.
 *
 * @return {String} the program ID for the current page
 */
const programId = () => {
  return metaTagContent('VHL.program_id');
};

/**
 * This method gives output which does not match with the given condition.
 * @param {Array} arr - Input list to be filtered.
 * @param {Function} predicate - Condition to be used for filtering.
 * @return {Function}
 */
function reject(arr, predicate) {
  const complement = function(func) {
    return function(x) {
      return !func(x);
    };
  };

  return arr.filter(complement(predicate));
}

/**
 * Scrolls back to the top of the window.  This is useful for features that use
 * client side routing in which changing screens does not cause the browser
 * to move the user back up to the top of the page.
 */
function scrollToTopOfPage() {
  window.scrollTo(0, 0);
}

/**
 * Scrolls to the bottom of the window.  This is useful when adding new options at the bottom of a page
 */
function scrollToBottomOfPage() {
  window.scrollTo(0, document.body.scrollHeight);
}

/**
 * @summary Get the section ID for the page.
 * Looks up the VHL.section_id <meta> tag and gets its value.
 *
 * @return {String} the program ID for the current page
 */
const sectionId = () => {
  return metaTagContent('VHL.section_id');
};

/**
 * Replaces the specified image element with a new element.
 * The replacement will have its src attribute set to the
 * media item public filepath retrieved from the mediaLookup, which is
 * a hash of media ids to filepaths. The media lookup is a property of
 * the activity in custom assessments. If the original element has no id attr,
 * or there is no entry for the id in the mediaLookup,
 * the original element is not replaced.
 * @param {Element} oldElm - The image node to be replaced.
 * @param {Object} mediaLookup - A hash of media ids to filepaths.
 */
function setImageMedia(oldElm, mediaLookup) {
  const mediaId = oldElm.getAttribute('id');
  if (mediaId) {
    const imageSrc = mediaLookup[mediaId]?.src;
    if (imageSrc) {
      const newElm = document.createElement('img');
      newElm.setAttribute('src', imageSrc);
      oldElm.replaceWith(newElm);
    }
  }
}

/**
 * Sort an array of objects by the specified property of each
 * object in asc/desc order.
 * @param {Array.<Object>} arr - array to be sorted.
 * @param {string} key - key according to which sorting is done.
 * @param {string} direction - asc/desc
 * @return {Array.<Object>}
 */
function sort(arr, key, direction) {
  const sortedArray = arr.concat().sort(sortBy(key));
  return direction === 'asc' ? sortedArray : sortedArray.reverse();
}

/**
 * @private
 * Sort by the key passed in argument
 * @param {String} key
 * @return {Object}
 */
function sortBy(key) {
  return (a, b) => (a[key] > b[key]) ? 1 : ((b[key] > a[key]) ? -1 : 0);
}

/**
 * This strips out any entered html tags from the given text.
 * This function assigns html to a temporary div, then gets its textContent
 * which would ensure that any tags nested at any level are stripped out.
 * @param {string} htmlText - text that may have html tags
 * @return {string}
 */
function stripTags(htmlText) {
  const wrapperElm = document.createElement('div');
  wrapperElm.innerHTML = htmlText;
  return wrapperElm.textContent;
}

/**
 * Calculates the sum of values of an array.
 * @param {Array.<number>} arr - given array.
 * @return {number}
 */
function sum(arr) {
  return arr.reduce((sum, val) => sum + val, 0);
}

/**
 * @summary Return a test-class string in test environment only.
 * The returned string may be used in JS unit tests and Rails integration
 *   tests. It should not be visible in the page source in the dev, qa, or
 *   production environments.
 *
 * @deprecated To be removed from this location after we ship moving it to music
 * @param {String} suffix - The name to appear after test- prefix.
 * @return {String} the given argument, prefixed by 'test-' (in test env only)
 */
const testClass = (suffix) => {
  const testEnvValue = 'test';
  if (
    [
      process.env['NODE_ENV'],
      process.env['RAILS_ENV'],
    ].every((envValue) => envValue !== testEnvValue)
  ) {
    return '';
  }

  return `test-${suffix}`;
};

/**
 * joins an array with "and" and commas'.
 * @param {Array<string>} arr - The array to convert to a sentence.
 * @return {string}
 */
function toSentence(arr) {
  const last = arr.pop();
  const sentence = arr.length === 0 ? last : `${arr.join(', ')} and ${last}`;
  return sentence;
}

/**
 * Produces a duplicate-free version of the array.
 * @param {Array} arr - given array.
 * @return {Array}
 */
const unique = (arr) => {
  return [...new Set(arr)];
};

/**
 * Get whether provided argument is a function or not
 * @param {*} func - Provided argument
 * @return {boolean} - Whether provided argument is a function or not
 */
function isFunction(func) {
  return func && typeof func === 'function';
}

/**
 * Reduce object - similar to Array.reduce but used for objects.
 * @param {Object} obj - Object to be reduced.
 * @param {*} initialValue - Initial memo value for reducer
 * @param {Function} reducerFn - A function to execute on each key/value
 * in the object to be reduced
 * @return {*} - Reduced value.
 */
function reduceObject(obj, initialValue, reducerFn) {
  const keys = Object.keys(obj);
  const length = keys.length;
  let memo = initialValue;
  for (let index = 0; index < length; index++) {
    const currentKey = keys[index];
    memo = reducerFn(memo, obj[currentKey], currentKey, obj);
  }
  return memo;
}

/**
 * Get sorted list of items by transformed value using a transformation function.
 * @param {Array} list - List containing the items.
 * @param {Function} transformationFn - Transformation function.
 * @return {Array} - Sorted items
 */
function sortByFunction(list, transformationFn) {
  const comparerFn = (a, b) => {
    const transformedA = transformationFn(a);
    const transformedB = transformationFn(b);
    return (transformedA > transformedB) ? 1 : ((transformedB > transformedA) ? -1 : 0);
  };
  // Use .concat() to return new array instead of in place modification
  return list.concat().sort(comparerFn);
}

/**
 * Get union of 2 arrays.
 * @param {Array} arr1 - First array.
 * @param {String} arr2 - Second array.
 * @return {Array}
 */
function union(arr1 = [], arr2 = []) {
  return unique([arr1, arr2].flat());
}

/**
 * Get filtered array with unique items using a transformation function
 * to compare item's uniqueness.
 * @param {Array} list - List containing the items.
 * @param {Function} transformationFn - Transformation function.
 * @return {Array} - List of unique items
 */
function uniqueWithFunction(list, transformationFn) {
  const transformedArr = list.map(transformationFn);
  const newList = [];
  transformedArr.forEach((value, index, self) => {
    if (self.indexOf(value) === index) {
      newList.push(list[index]);
    }
  });
  return newList;
}

/**
 * Check if key is a direct property of an object.
 * @param {Object} obj - Object in which given key is searched
 * @param {string} key - searched key
 * @return {boolean} - Whether key is a direct property of an object.
 */
function hasKeyInObject(obj, key) {
  // If obj is falsey (e.g. 0, null, undefined, etc.), !!obj will be false.
  return !!obj && hasOwnProperty.call(obj, key);
}

/**
 * Return text with Chinese characters wrapped in <span lang="zh"></span>
 * @param {string} requestText - Text with Chinese characters.
 * @return {string} - Text with Chinese characters wrapped in <span lang="zh"></span>.
 */
function processChineseText(requestText) {
  /**
   * For chinese program we want to wrap the chinese text that comes from
   * places like help requests and score requests, inside <span lang="zh"> tags
   * so that the text is displayed in the correct size and style.
   * Also since student can add any text in their help requests, we escape
   * their request text to avoid malicious behaviro libe adding <script> tags.
   */
  const regexp = /(\d*\p{Script=Han}+[\d\p{P}\s\p{Script=Han}]*)/ug;
  return escape(requestText).replace(regexp, '<span lang="zh">$1</span>');
};

/**
 * Redirects the browser to the specified URL.
 * @param {String} [url] - The URL to which the browser will be redirected.
 */
function redirectToUrl(url) {
  window.location.href = url;
}

function appcuesId(id) {
  return `appcues-${id}`;
}

export {
  appcuesId,
  cloneObject,
  compose,
  dispatchCustomEvent,
  firstInArray,
  getSearchParam,
  groupBy,
  hasHtml,
  hasKeyInObject,
  htmlToPlainText,
  humanize,
  isEmpty,
  isFunction,
  isObjEmpty,
  isValidExternalUrl,
  lastInArray,
  maxInArray,
  metaTagContent,
  omit,
  pick,
  pluck,
  processChineseText,
  programId,
  reduceObject,
  redirectToUrl,
  reject,
  scrollToBottomOfPage,
  scrollToTopOfPage,
  sectionId,
  setImageMedia,
  sort,
  sortByFunction,
  stripTags,
  sum,
  testClass,
  toSentence,
  union,
  unique,
  uniqueWithFunction,
};
