import { defineStore } from 'pinia';
import TourGuide from './tour_guide';

const useTourGuideStore = defineStore(
  'tourGuide',
  {
    state: () => {
      return {
        tourGuide: null,
      };
    },
    actions: {
      init(user, programId, customTriggers) {
        this.tourGuide = new TourGuide(user, programId, customTriggers);
        this.tourGuide.initialize();
      },
    },
  }
);

export default useTourGuideStore;
