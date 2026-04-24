import { createApp } from 'vue';
import { ColumnMatchingApp } from 'mae';

document.addEventListener(
  'DOMContentLoaded',
  () => {
    const rootElm = document.querySelector('.js-column-matching-app');

    createApp(ColumnMatchingApp, { ...rootElm.dataset }).mount(rootElm);
  }
);
