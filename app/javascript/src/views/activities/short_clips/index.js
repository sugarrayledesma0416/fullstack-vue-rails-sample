import { ShortClipsApp } from 'mae';
import { mountVueAppOnElm } from 'shared/utils/vue';

document.addEventListener('DOMContentLoaded', () => {
  mountVueAppOnElm(ShortClipsApp, '.js-short-clips-app', true);
});

