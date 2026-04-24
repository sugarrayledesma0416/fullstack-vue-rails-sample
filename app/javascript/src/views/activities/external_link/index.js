import { mountVueAppOnElms } from 'shared/utils/vue';
import { ExternalLinkApp } from 'mae';

document.addEventListener('DOMContentLoaded', () => {
  mountVueAppOnElms(ExternalLinkApp, '.js-external-link-app');
});
