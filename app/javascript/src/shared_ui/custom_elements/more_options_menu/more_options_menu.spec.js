import M3MoreOptionsMenu from './more_options_menu';
import menuClasses from './_more_options_menu.module.scss';
customElements.define('m3-more-options-menu', M3MoreOptionsMenu);
let wrapper;
let items;
let menu;

const menuTemplate = () => {
  wrapper = document.createElement('m3-more-options-menu');
  menu = document.createElement('sl-menu');

  items = [1, 2].map(i => {
    const item = document.createElement('sl-menu-item');
    item.textContent = `Item ${i}`;
    menu.appendChild(item);
    return item;
  });

  wrapper.appendChild(menu);
}

// If there are no sl-menu-items, skip creating template
// and attaching events.
const menuTemplateNoItems = () => {
  wrapper = document.createElement('m3-more-options-menu');
  menu = document.createElement('sl-menu');

  wrapper.appendChild(menu);
}

beforeEach(() => {
  document.body.innerHTML = '';
  wrapper = document.createElement('m3-more-options-menu');
});

describe('M3MoreOptionsMenu', () => {
  describe('when there are sl-menu-item nodes', () => {
    it('creates the component', () => {
      expect(wrapper).toBeInstanceOf(M3MoreOptionsMenu);
    });

    it('contains a trigger button', () => {
      menuTemplate()
      document.body.appendChild(wrapper)
      expect(wrapper.querySelector('sl-icon-button')).not.toBe(null);
    });
  });

  describe('when there are no sl-menu-item nodes', () => {
    it('Does not replace the template & hides the element', () => {
      menuTemplateNoItems()
      document.body.appendChild(wrapper)
      expect(wrapper.classList.contains('u-dis-none')).toBe(true);
      expect(wrapper.querySelector('sl-icon-button')).toBe(null);
    });
  });
});
