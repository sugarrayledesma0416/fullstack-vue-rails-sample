import { PronunciationExploreApp  } from 'mae';
import {
  mountPronunciationExploreApp,
} from 'mae/app/javascript/src/features/pronunciation_explore';

document.addEventListener('DOMContentLoaded', () => {
  mountPronunciationExploreApp('.js-pronunciation-explore-app');
});
