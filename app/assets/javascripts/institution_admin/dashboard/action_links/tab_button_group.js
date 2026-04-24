/* global VHL */

VHL.InstitutionAdmin = VHL.InstitutionAdmin || {};

VHL.InstitutionAdmin.TabButtonGroup = class TabButtonGroup {
  constructor(selector = '.js-tab-button-group') {
    this.container = document.querySelector(selector);
    this.init();
  }

  // Add a visual indicator to the current tab.
  init() {
    let subnavElms = [...this.container.querySelectorAll('.c-tab')];

    /** Iterate over the tabs.
     *    When you reach the tab whose name is part of the current location,
     *    add the "is-current" class to it.
     */
    for (const elm of subnavElms) {
      if (location.pathname.search(elm.name) > -1) {
        elm.classList.add('is-current');

        /** Because only one tab can be marked as current,
         *    the loop can terminate now.
         */
        break;
      }
    };
  }
};
