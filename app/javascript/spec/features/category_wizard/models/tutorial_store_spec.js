import TutorialStore from 'features/category_wizard/models/tutorial_store';

let tutorialStore;

describe('TutorialStore Model', () => {
  describe('initialize TutorialStore model', () => {
    beforeEach(() => {
      tutorialStore = new TutorialStore();
    });

    it('initializes examples attribute', () => {
      expect(tutorialStore.examples).toStrictEqual([
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
      ]);
    });
  });

  describe('#getStarted', () => {
    beforeEach(() => {
      tutorialStore = new TutorialStore();
    });

    it('starts the category wizard', () => {
      tutorialStore.store.active = true;
      tutorialStore.getStarted();
      expect(tutorialStore.store.active).toBeFalsy();
    });
  });

  describe('#closeTutorial', () => {
    beforeEach(() => {
      tutorialStore = new TutorialStore();
    });

    it('closes the tutorial section', () => {
      tutorialStore.store.active = true;
      tutorialStore.closeTutorial();
      expect(tutorialStore.store.active).toBeFalsy();
    });
  });

  describe('#viewTutorial', () => {
    beforeEach(() => {
      tutorialStore = new TutorialStore();
    });

    it('shows the tutorial section', () => {
      tutorialStore.store.active = false;
      tutorialStore.viewTutorial();
      expect(tutorialStore.store.active).toBeTruthy();
    });
  });
});
