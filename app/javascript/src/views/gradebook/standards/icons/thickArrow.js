import { BaseIcon } from 'music/app/javascript/src/custom_elements/icons/_base_icon_class.js';

class ThickArrow extends BaseIcon {
  constructor() {
    super();
    this.label = 'Thick arrow';
  }

  static get svg() {
    return `<svg viewBox="0 0 100 100" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><title>Thick Arrow</title><g id="Thick-Arrow" stroke="none" stroke-width="1" fill="inherit" fill-rule="evenodd"><path d="M65.8830561,88.2151507 L65.8830561,51.6282737 L85.2492678,51.6282737 C88.5783989,51.6282737 90.2585212,47.5280203 87.8939047,45.1624894 L52.1446369,9.11179949 C50.6823082,7.62940017 48.3488051,7.62940017 46.8864765,9.11179949 L11.1060953,45.1624894 C8.74147882,47.5595607 10.4216011,51.6282737 13.7507322,51.6282737 L33.4966452,51.6282737 L33.4966452,88.2151507 C33.4966452,90.2968178 35.1767675,92 37.2302502,92 L62.1494512,92 C64.2029339,92 65.8830561,90.2968178 65.8830561,88.2151507 Z" id="Shape" fill-rule="nonzero"></path></g></svg>`;
  }
}

window.customElements.define('vhl-thick-arrow-icon', ThickArrow);
