import { mountVueAppOnElm } from 'shared/utils/vue';
import { HotspotsActivityApp } from 'mae';

document.addEventListener(
  'DOMContentLoaded',
  () => {
    const interstitialContainer = document.querySelector('.js-interstitial');

    if (interstitialContainer) {
      const exploreBtn = document.querySelector('.js-explore-selector');
      const presetantionBtn = document.querySelector('.js-presentation-selector');

      exploreBtn.addEventListener('click', () => {
        interstitialContainer.classList.add('u-hidden');
        mountVueAppOnElm(HotspotsActivityApp, '.js-hotspots-activity-app');
      });

      presetantionBtn.addEventListener('click', () => {
        interstitialContainer.classList.add('u-hidden');
        const presentationModeElm = document.querySelector('.js-presentation-mode');
        presentationModeElm.classList.remove('u-hidden');
        presentationModeElm.querySelector('.js-overlay-start').focus();
      });
    } else {
      mountVueAppOnElm(HotspotsActivityApp, '.js-hotspots-activity-app');
    }
  }
);
