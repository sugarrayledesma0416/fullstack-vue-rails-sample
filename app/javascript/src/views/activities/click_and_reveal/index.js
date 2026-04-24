import { mountVueAppOnElm } from 'shared/utils/vue';
import { ClickAndRevealApp } from 'mae';

document.addEventListener(
  'DOMContentLoaded',
  () => {
    mountVueAppOnElm(ClickAndRevealApp, '.js-click-and-reveal-app');
  }
);
