import { createApp } from 'vue';
import { CustomAssessmentsApp, VueFroala } from 'mae';
import 'froala-editor/css/froala_editor.min.css';
import 'froala-editor/css/froala_style.min.css';
import 'froala-editor/js/plugins/lists.min.js';
import 'froala-editor/js/plugins/table.min.js';
import 'froala-editor/css/plugins/table.css';
import 'froala-editor/js/plugins/align.min.js';
import 'froala-editor/js/plugins/image.min.js';
import 'froala-editor/css/plugins/image.min.css';
import 'froala-editor/js/plugins/special_characters.min.js';

document.addEventListener(
  'DOMContentLoaded',
  () => {
    // The virtual chat metadata get populated by reading from metadata
    // tags on page load. If the instructor hasn't already selected their
    // gender, we don't want to pop up confusing dialogs while they're in
    // the process of importing content. so just default them to one gender.
    VHL.VChat.baseMetadata.user_gender = VHL.VChat.baseMetadata.user_gender || 'Female';
    VHL.VVChat.baseMetadata.user_gender = VHL.VVChat.baseMetadata.user_gender || 'Female';

    const customAssessmentsRootElm = document.querySelector('.js-custom-assessments-app');

    const mainApp = createApp(
      CustomAssessmentsApp, { ...customAssessmentsRootElm.dataset }
    );
    mainApp.use(VueFroala);
    mainApp.mount(customAssessmentsRootElm);

    const stickyMenuBarTop = document.querySelector('.js-sticky-menu-bar-top');
    const stickyMenuAddSection = document.querySelector('.js-sticky-menu-add-section');
    const topOffset = stickyMenuBarTop.offsetTop;

    window.onscroll = () => stickyAction(topOffset, stickyMenuBarTop, stickyMenuAddSection);
  }
);

/**
 * @param {number} topOffset - The current y position of the sticky menu.
 * @param {HtmlElement} stickyMenuBarTop - The element at the top of the
 * sticky menu bar.
 * @param {HtmlElement} stickyMenuAddSection - The Add Section menu, which
 * sits to the left of the main well, which is also sticky upon scroll.
 */
function stickyAction(topOffset, stickyMenuBarTop, stickyMenuAddSection) {
  if (window.pageYOffset >= topOffset) {
    stickyMenuBarTop.classList.add(
      'u-pos-fixed',
      'u-width-full',
      'u-stick-menu-top',
      'u-pad-rt-64',
      'u-z-10'
    );
    stickyMenuBarTop.querySelector('.js-sticky').classList.add('u-pad-rt-16');
    stickyMenuBarTop.classList.remove('u-mar-top-24');
    stickyMenuAddSection.classList.add(
      'add-section-menu--is-open',
      'u-mar-top-neg-6',
      'u-pos-fixed',
      'u-z-9'
    );
  } else {
    stickyMenuBarTop.classList.remove(
      'u-pos-fixed',
      'u-width-full',
      'u-stick-menu-top',
      'u-pad-rt-64',
      'u-z-10'
    );
    stickyMenuBarTop.querySelector('.js-sticky').classList.remove('u-pad-rt-16');
    stickyMenuBarTop.classList.add('u-mar-top-24');
    stickyMenuAddSection.classList.remove(
      'add-section-menu--is-open',
      'u-mar-top-neg-6',
      'u-pos-fixed',
      'u-z-9'
    );
  }
}
