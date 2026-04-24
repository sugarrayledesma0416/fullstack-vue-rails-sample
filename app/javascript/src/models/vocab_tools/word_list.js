import * as ajaxUtils from 'shared/ajax_utils';
import Lesson from './lesson';
import { groupBy } from 'shared/utils';

/** Class representing WordList */
class WordList {
  /**
   * Get Url to fetch Word List for a lesson.
   * When lesson is not present, return current url in json extention.
   * eg https://../vocab_tools/words.json?unit_id=1"
   *
   * @param {Object} [lesson] - Lesson object
   * @param {String} lesson.name - Name of a lesson.
   * @param {Number} lesson.id - Id of a lesson.
   * @return {String} - url
   */
  static url(lesson) {
    const lessonId = lesson === undefined ? '' : lesson.id;
    const urlParts = location.href.split('?');
    let url = urlParts[0] + '.json';
    if (lesson) {
      url += '?lesson_id=' + lessonId;
    } else if (urlParts[1]) {
      url += '?' + urlParts[1];
    }
    return url;
  }

  /**
   * Get Word List for a lesson.
   *
   * @param {Object} [lesson] - Lesson object
   * @param {String} lesson.name - Name of a lesson.
   * @param {Number} lesson.id - Id of a lesson.
   * @return {Promise} - promise that resolve to json retrieve from endpoint.
   */
  static forLesson(lesson) {
    return new Promise((resolve) => {
      ajaxUtils.getFromEndpoint(
        this.url(lesson),
        (data) => {
          resolve(data);
        }
      );
    });
  }

  /**
   * Group Word list by Lesson ID.
   *
   * @param {Array} list - List of Words
   * list example:
   *  [{ target: 'foo', lesson_id: 1, topic: 'Saludos'},
   *  { target: 'bar', lesson_id: 1, topic: 'Títulos'}]
   * @param {Boolean} [selected=false]
   * @return {Array} - lessons
   * lessons example:
   * [{ id: 1,
   *    selected: true,
   *    topics: [{
   *      name: 'Saludos', words: [{ target: 'foo', lesson_id: 1, topic: 'Saludos'}]
   *    },
   *    {
   *      name: 'Títulos', words: [{ target: 'bar', lesson_id: 1, topic: 'Títulos'}]
   *    }]
   * }]
   */
  static organize(list, selected = false) {
    const lessons = [];
    const groupByList = groupBy(list, 'lesson_id');

    /**
     * The body of a for-in should be wrapped in an if statement to filter
     * unwanted properties from the prototype.
     */
    for (const lessonId in groupByList) {
      if (Object.prototype.hasOwnProperty.call(groupByList, lessonId)) {
        const lessonWords = groupByList[lessonId];
        lessons.push(new Lesson({
          id: parseInt(lessonId),
          words: lessonWords,
        }, selected));
      }
    }
    return lessons;
  }
}

export default WordList;
