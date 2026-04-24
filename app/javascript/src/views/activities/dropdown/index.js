import { createApp } from 'vue';
import ActivityDropdown from
  'mae/app/javascript/src/features/dropdown/ActivityDropdown.vue';

window.addEventListener(
  'DOMContentLoaded',
  () => {
    /** dropdownContainer is a container to move the listBox element out and
     * fix overflow issues when it is mobile and table activity. */
    const dropdownContainer = document.createElement('div');

    dropdownContainer.id = 'dropdown_activity_menu_layer';
    document.body.appendChild(dropdownContainer);
    mountDropdownAppsOnElms(ActivityDropdown, '.js-activity-dropdown-wrapper');
  }
);

const mountDropdownAppsOnElms = (appClass, selector) => {
  const elms = document.querySelectorAll(selector);
  elms.forEach((elm) => {
    const props = { ...elm.dataset };
    if (props.listData) {
      props.listData = JSON.parse(props.listData);
    }
    if (props.disabled) {
      props.disabled = props.disabled === 'true';
    }
    if (props.selectedIndex) {
      props.selectedIndex = Number(props.selectedIndex);
    }

    const app = createApp(
      appClass,
      props
    );

    app.mount(elm);
  });

  document.body.addEventListener('activitydropdownchange', window.has_unsaved_work);
};
