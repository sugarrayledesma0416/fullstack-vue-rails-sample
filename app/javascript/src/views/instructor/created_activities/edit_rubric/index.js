import 'froala-editor/css/froala_editor.min.css';
import 'froala-editor/css/froala_style.min.css';
import 'froala-editor/js/plugins/lists.min.js';
import 'tippy.js/dist/tippy.css';

import { createApp } from 'vue';
import { createPinia } from 'pinia';
import VueFroala from 'directives/vue_froala';
import EditRubricApp from 'features/rubrics/EditRubricApp';
import FroalaEditor from 'froala-editor';
import VueTippy from 'vue-tippy';

/*
 * Froala uses different lists types than those used in the maestro_activity_engine.
 * So we set two custom buttons that display the list mae list options with their
 * descriptions.
 */
/* eslint-disable new-cap */
FroalaEditor.RegisterCommand('formatMaestroUL', {
  title: 'Unordered List',
  type: 'button',
  hasOptions: () => true,
  options: {
    disc: 'Bullet',
    none: 'Non visible',
  },
  refresh: function(e) {
    this.lists.refresh(e, 'UL');
  },
  callback: function(e, t) {
    this.lists.format('UL', (t === undefined ? 'disc' : t));
  },
  plugin: 'lists',
});
FroalaEditor.RegisterCommand('formatMaestroOL', {
  title: 'Ordered List',
  hasOptions: () => true,
  options: {
    'decimal': 'Decimal',
    'lower-alpha': 'Lower Alphabetic',
    'lower-roman': 'Lower Roman',
    'upper-alpha': 'Upper Alphabetic',
    'upper-roman': 'Upper Roman',
  },
  refresh: function(e) {
    this.lists.refresh(e, 'OL');
  },
  callback: function(e, t) {
    this.lists.format('OL', t);
  },
  plugin: 'lists',
});
FroalaEditor.DefineIcon('formatMaestroUL', { NAME: 'list-ul', SVG_KEY: 'unorderedList' });
FroalaEditor.DefineIcon('formatMaestroOL', { NAME: 'list-ol', SVG_KEY: 'orderedList' });
/* eslint-enable new-cap */

document.addEventListener(
  'DOMContentLoaded',
  () => {
    const elm = document.querySelector('.js-edit-rubric-app');
    const app = createApp(EditRubricApp, { ...elm.dataset });
    app.use(createPinia());
    app.use(VueFroala);
    app.use(VueTippy);
    app.mount(elm);
  }
);
