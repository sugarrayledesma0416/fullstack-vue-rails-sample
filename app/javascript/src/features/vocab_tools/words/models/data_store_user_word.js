import Topic from 'models/vocab_tools/topic';

/**
 * This class provides methods to update vocab tools app state via add/edit/delete user word.
 */
export default class DataStoreUserWord {
  /**
   * Store reference of reactive object which stores vocab tools app state
   * @constructor
   * @param {Object} localStore - Reactive object which stores vocab tools app state
   */
  constructor(localStore) {
    this.localStore = localStore;
  }

  /**
   * Update localStore by adding user word to the list of words for the lesson.
   * @param {Number} unitId - Id of the corresponding unit.
   * @param {Number} lessonId - Id of the corresponding lesson.
   * @param {Object} word - Word to be added.
   */
  addUserWord(unitId, lessonId, word) {
    const data = this.getUserWordRelevantData(unitId, lessonId);
    const lesson = data.lesson;
    let topic = data.topic;
    if (!topic) {
      topic = new Topic({
        name: 'My Words',
        words: [],
      });
      lesson.topics.unshift(topic);
    }
    topic.addWord(word);
    topic.selected = true;
  }

  /**
   * Update localStore by removing user word from the list of words for the lesson.
   * @param {Number} unitId - Id of the corresponding unit.
   * @param {Number} lessonId - Id of the corresponding lesson.
   * @param {Object} word - Word to remove.
   */
  removeUserWord(unitId, lessonId, word) {
    const data = this.getUserWordRelevantData(unitId, lessonId);
    const lesson = data.lesson;
    const topic = data.topic;
    // if there is no user-words topic, get out
    if (!topic) return;

    topic.removeWord(word);
    this.removeTopicIfEmpty(topic, lesson);
  }

  /**
   * Update localStore by updating user word to the list of words for the lesson.
   * @param {Number} unitId - Id of the corresponding unit.
   * @param {Number} lessonId - Id of the corresponding lesson.
   * @param {Object} wordToUpdate - word to update.
   */
  updateUserWord(unitId, lessonId, wordToUpdate) {
    const data = this.getUserWordRelevantData(unitId, lessonId);
    const topic = data.topic;
    const word = topic.words.find((word) => word.id === wordToUpdate.id);
    word.target = wordToUpdate.target;
    word.translation = wordToUpdate.translation;
    word.definition = wordToUpdate.definition;
    word.pinyin = wordToUpdate.pinyin;
  }

  /**
   * @private
   * Get Unit, Lesson and Topic object.
   * @param {Number} unitId
   * @param {Number} lessonId
   * @return {Object} - returns unit, lesson and topic(with name as "My Words")
   */
  getUserWordRelevantData(unitId, lessonId) {
    const unit = this.localStore.units.find((unit) => unit.id === unitId);
    const lesson = unit.lessons.find((lesson) => lesson.id === lessonId);
    const topic = lesson.topics.find((topic) => topic.name === 'My Words');
    return { lesson, topic, unit };
  }

  /**
   * @private
   * @param {Topic} topic - A Topic Object which needs to removed if no words exists.
   * @param {Lesson} lesson - A Lesson Object corresponding to the topic.
   */
  removeTopicIfEmpty(topic, lesson) {
    if (topic.wordCount === 0) {
      const topicIndex = lesson.topics.indexOf(topic);
      if (topicIndex > -1) {
        lesson.topics.splice(topicIndex, 1);
      }
    }
  }
}
