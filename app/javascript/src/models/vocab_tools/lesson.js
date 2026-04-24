import { groupBy } from 'shared/utils';
import Topic from './topic';

/**
 * Class representing Lesson.
 */
class Lesson {
  /**
   * Instantiate the Lesson class.
   * @param {Object} lesson - Lesson for vocab tools.
   * @param {String} lesson.name - Name of a lesson.
   * @param {Number} lesson.id - Id of a lesson.
   * @param {Array} lesson.words - Array of words in lesson.
   * @param {String} lesson.displayName - Display Name of a lesson.
   * @param {Boolean} lesson.expanded - Whether lesson disclosure is expanded.
   * @param {Boolean} lesson.inCourse - Whether lesson is in course.
   * @param {String} lesson.label - Label of a lesson.
   * @param {Array} lesson.parent - List of lessons in the parent unit of a lesson.
   * @param {Boolean} selected - Whether lesson is selected.
   */
  constructor(lesson, selected = false) {
    this.id = lesson.id;
    this.name = lesson.name;
    this.words = lesson.words === undefined ? [] : lesson.words;
    this.selected = selected;
    this.displayName = lesson.displayName;
    this.expanded = lesson.expanded;
    this.inCourse = lesson.inCourse;
    this.label = lesson.label;
    this.parent = lesson.parent;
    // This flag is to store whether the topics are retrived from DB for this lesson.
    this.isRetrieved = false;
    this.createTopics();
  }

  /**
   * Gets word count for a lesson.
   * @return {Number} - Word count for a lesson.
   */
  get wordCount() {
    return this.topics.reduce((initialValue, topic) => initialValue + topic.wordCount, 0);
  }

  /**
   * Create array of topics object corresponding to the lesson.
   */
  createTopics() {
    const wordsCopy = this.words.slice();
    this.topics = [];
    const emptyTopic = new Topic({
      name: '',
      words: [],
    }, this.selected);
    emptyTopic.selected = false;
    this.topics.push(emptyTopic);

    const groupByList = groupBy(wordsCopy, 'topic');

    /**
     * The body of a for-in should be wrapped in an if statement to filter
     * unwanted properties from the prototype.
     */
    for (const topicName in groupByList) {
      if (Object.prototype.hasOwnProperty.call(groupByList, topicName)) {
        const topicWords = groupByList[topicName];
        this.topics.push(new Topic({
          name: topicName,
          words: topicWords,
        }, this.selected));
      }
    }
  }

  /**
   * Get Words corresponding to the unit which are selected.
   * @return {Array} - words corresponding to the unit which are selected.
   */
  selectedWords() {
    // Set is used to make collection of words as unique. Basically, applying union.
    return this.topics.reduce(
      (initialArr, topic) => [...new Set([...initialArr, ...topic.selectedWords])],
      []
    );
  }

  /**
   * Stops Audio.
   */
  stopAudio() {
    this.topics.forEach((topic) => topic.stopAudio());
  }

  /**
   * De-Select all the topics.
   */
  deselectAll() {
    this.topics.forEach((topic) => topic.selected = false );
  }

  /**
   * Checks whether there is any selected topic or not.
   * @return {Boolean}
   */
  hasSelectedTopics() {
    return this.topics.map((topic) => topic['selected']).some((selectedValue) => {
      return selectedValue;
    });
  }

  /**
   * Checks if any topic is empty or not
   * @return {Boolean}
   */
  hasFilledTopics() {
    return this.topics.filter((topic) => {
      return !topic.isEmpty;
    });
  }
}

export default Lesson;
