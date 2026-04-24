import { mountVueAppOnElm } from 'shared/vue_utils';
import { DiagnosticV2App } from 'mae';

document.addEventListener(
  'DOMContentLoaded',
  () => {
    if (document.querySelector('.js-diagnostic-v2-app')) {
      mountVueAppOnElm(DiagnosticV2App, '.js-diagnostic-v2-app');
    }
  }
);
