import { reactive } from 'vue';

/** Class for TutorialStore Model. */
export default class TutorialStore {
  /**
   * @constructor
   * TutorialStore
   */
  constructor() {
    this.examples = [
      {
        text: 'In your gradebook, each activity you assign...',
        image: '/images/course_wizard/1a_zoom.jpg',
        zoomedImage: '/images/course_wizard/1a_jb.jpg',
        css: 'toc',
      },
      {
        text: '...needs to be associated with a category.',
        image: '/images/course_wizard/3a_zoom.jpg',
        zoomedImage: '/images/course_wizard/3a_jb.jpg',
        css: 'assign',
      },
      {
        text: 'The categories you create are used to calculate your students\' final grades.',
        image: '/images/course_wizard/2a_zoom.jpg',
        zoomedImage: '/images/course_wizard/2a_jb.jpg',
        css: 'grade',
      },
    ];
    this.store = reactive({
      active: false,
      showGettingStarted: true,
    });
  }

  /**
   * Change store active to false.
   */
  getStarted() {
    this.store.active = false;
  }

  /**
   * Closes the tutorial UI by changing the store active to false.
   */
  closeTutorial() {
    this.store.active = false;
  }

  /**
   * Toggle the tutorial UI by inverting the store active value.
   */
  toggleTutorial() {
    this.store.active = !this.store.active;
  }

  /**
   * Opens the tutorial UI by changing the store active to true.
   */
  viewTutorial() {
    this.store.active = true;
  }
}
