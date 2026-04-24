/*doc
---
title: More options Menu
name: m3-more-options-menu
category: M3 Components
---


This component is a dedicated dropdown menu for the more options menu, consisting of a trigger button (vertical dots) and a menu with menu items.

```html_example_table
<h3 class="demo-heading-3">Default More options Menu</h3>
<m3-more-options-menu>
  <sl-menu>
    <sl-menu-item>
      Option 1
    </sl-menu-item>
    <sl-menu-item>
      Option 2
    </sl-menu-item>
    <sl-menu-item>
      Option 3
    </sl-menu-item>
  </sl-menu>
</m3-more-options-menu>
```

## Slots

* Default slot: it should include sl-menu with sl-menu-item elements 

## Template

* Light DOM

## Methods

None

*/
import menuStyles from './_more_options_menu.module.scss';

export default class M3MoreOptionsMenu extends HTMLElement {

  connectedCallback() {
    this.storeOriginalContent();
    this.validateVisibility();
    this.attachResizeListener();
  }

  storeOriginalContent() {
    const slMenu = this.querySelector('sl-menu');
    if (slMenu && !this.originalMenuContent) {
      this.originalMenuContent = slMenu.innerHTML;
    }
  }

  validateVisibility() {
    const slMenu = this.querySelector('sl-menu');
    const menuItems = slMenu ? slMenu.querySelectorAll('sl-menu-item') : [];

    const hasVisibleItems = Array.from(menuItems).some(item => {
      const style = window.getComputedStyle(item);
      return style.display !== 'none' && style.visibility !== 'hidden' && style.opacity !== '0';
    });
    
    if (menuItems.length > 0 && hasVisibleItems) {
      this.classList.remove('u-dis-none');
      if (!this.isRendered) {
        this.innerHTML = this.template;
        this.attachEvents();
        this.isRendered = true;
      }
    } else {
      this.classList.add('u-dis-none');
    }
  }

  attachResizeListener() {
    this.resizeHandler = () => {
      this.validateVisibility();
    };
    window.addEventListener('resize', this.resizeHandler);
  }

  disconnectedCallback() {
    if (this.resizeHandler) {
      window.removeEventListener('resize', this.resizeHandler);
    }
  }

  get classes() {
    return {
      isSelected: menuStyles['is-selected'],
      triggerBtn: menuStyles['more-ptions-menu__trigger'],
    }
  }
  get template() {
    return `
    <sl-dropdown distance="-32">
      <sl-icon-button
            slot="trigger"
            name="dots-vertical"
            library="untitled-ui"
            class="${this.classes.triggerBtn}">
      </sl-icon-button>
      <sl-menu>
        ${this.originalMenuContent || ''}
      </sl-menu>
      </sl-dropdown>
    `;
  }

  attachEvents() {
    const menu = this.querySelector('sl-menu');
    menu.addEventListener('sl-select', event => {
      menu.querySelectorAll('sl-menu-item').forEach(item => {
        item.classList.remove(this.classes.isSelected);
        const anchor = item.querySelector('a');
        if (anchor.href) {
          window.location.href = anchor.href;
        }
      });
      event.detail.item.classList.add(this.classes.isSelected);
    });
  }
}
