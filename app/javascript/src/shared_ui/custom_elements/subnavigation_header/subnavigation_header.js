/*doc
---
title: Subnavigation header component
name: m3-subnavigation-header
category: M3 Components
---

This component is dedicated to displaying the page title, more options menu, 
and additional elements in the subnavigation view of the program navigation.

```html_example_table
<h3 class="demo-heading-3">Subnavigation header</h3>
<m3-subnavigation-header page-title="Page title">
  <sl-button>Button name</sl-button>
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
</m3-subnavigation-header>
```

## Attributes

* `page title` (string) - Sets h1 element with page title value

## Slots

* Default slot: it should include m3-more-options-menu and other elements like sl-button in this example

## Template

* Light DOM

## Methods

None

*/
import headerStyles from './_subnavigation_header.module.scss';

export default class M3SubnavigationHeader extends HTMLElement {

  static get observedAttributes() {
    return ['page-title', 'description', 'title-id'];
  }

  connectedCallback() {
    this.pageTitle = this.getAttribute('page-title');
    this.description = this.getAttribute('description');
    this.titleId = this.getAttribute('title-id') || 'a11y-page-title';
    this.innerHTML = this.template;
  }

  get classes() {
    return {
      heading: headerStyles['c-subnav-header__heading'],
      title: headerStyles['c-subnav-header__title']
    }
  }

  get template() {
    const moreOptionsMenu = this.querySelector('m3-more-options-menu');
    const otherElements = Array.from(this.querySelectorAll(':scope > :not(m3-more-options-menu)'))
      .map(el => el.outerHTML)
      .join('');
    const descriptionTemplate = this.description ?
      `<p class="${this.classes.heading}">${this.description}</p>` : '';
    return `
      <l-line-v3 align-x="between" align-y="0">
        <l-stack-v3 gap="0" class="${this.classes.heading}">
          <h1 id="${this.titleId}" class="${this.classes.title}">${this.pageTitle}</h1>
          ${descriptionTemplate}
        </l-stack-v3>
        ${otherElements.length > 0 ? otherElements : ''}
 
        ${moreOptionsMenu ? 
          `<m3-more-options-menu>${moreOptionsMenu.innerHTML}</m3-more-options-menu>` : ''}
      </l-line-v3>
    `;
  }

  attributeChangedCallback(attrName, oldValue, newValue) {
    if (newValue !== oldValue) {
      if (['page-title', 'description', 'title-id'].includes(attrName)) {
        this[attrName] = newValue;
      }
    }
  }
}
