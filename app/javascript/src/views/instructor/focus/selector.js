import { mountVueAppOnElm } from 'shared/vue_utils';
import FocusSelectorApp from 'features/focus_selector/FocusSelectorApp';

document.addEventListener('DOMContentLoaded', () => {
  mountVueAppOnElm(FocusSelectorApp, '.js-focus-selector');
});
