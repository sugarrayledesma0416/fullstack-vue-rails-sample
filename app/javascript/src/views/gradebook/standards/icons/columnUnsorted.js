import { BaseIcon } from 'music/app/javascript/src/custom_elements/icons/_base_icon_class.js';

class ColumnUnsortedIcon extends BaseIcon {
  constructor() {
    super();
    this.label = 'unsorted';
  }

  static get svg() {
    return `<svg version="1.1" viewBox="0 0 50.8 82.55" xml:space="preserve" xmlns="http://www.w3.org/2000/svg"><g transform="translate(-152.4 69.85)" fill="#666" stroke-width=".26458"><path d="m177.8-69.85 25.4 25.4-3.175 3.175-22.225-22.225-22.225 22.225-3.175-3.175z"/><path d="m177.8 12.7 25.4-25.4-3.175-3.175-22.225 22.225-22.225-22.225-3.175 3.175z"/></g></svg>`;
  }
}

window.customElements.define('vhl-column-unsorted-icon', ColumnUnsortedIcon);
