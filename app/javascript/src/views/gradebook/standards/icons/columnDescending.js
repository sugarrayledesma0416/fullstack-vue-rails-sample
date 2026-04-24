import { BaseIcon } from 'music/app/javascript/src/custom_elements/icons/_base_icon_class.js';

class ColumnDescendingIcon extends BaseIcon {
  constructor() {
    super();
    this.label = 'sorted descending';
  }

  static get svg() {
    return `<svg version="1.1" viewBox="0 0 50.8 82.55" xml:space="preserve" xmlns="http://www.w3.org/2000/svg"><g transform="translate(-152.4 69.85)" stroke-width=".26458"><path d="m177.8-69.85 25.4 25.4-3.175 3.175-22.225-22.225-22.225 22.225-3.175-3.175z" fill="#666"/><path d="m177.8 12.7 25.4-25.4h-50.8z" fill="#333"/></g></svg>`;
  }
}

window.customElements.define('vhl-column-descending-icon', ColumnDescendingIcon);
