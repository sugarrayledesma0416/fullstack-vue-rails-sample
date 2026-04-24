import { BaseIcon } from 'music/app/javascript/src/custom_elements/icons/_base_icon_class.js';

class MagnifyingGlassIcon extends BaseIcon {
  constructor() {
    super();
    this.label = 'Search';
  }

  static get svg() {
    return `<svg width="19px" height="20px" viewBox="0 0 19 20" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
              <!-- Generator: Sketch 53.2 (72643) - https://sketchapp.com -->
              <title>Search</title>
              <desc>Search</desc>
              <g id="Account-Creation" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
                  <g id="M-School-List" transform="translate(-281.000000, -401.000000)" stroke="#006BAE" stroke-width="1.5">
                      <path d="M289,416 C285.134007,416 282,412.865993 282,409 C282,405.134007 285.134007,402 289,402 C292.865993,402 296,405.134007 296,409 C296,412.865993 292.865993,416 289,416 Z M294,415 L299,420 L294,415 Z" id="Combined-Shape"></path>
                  </g>
              </g>
            </svg>`;
  }
}

window.customElements.define('vhl-magnifying-glass-icon', MagnifyingGlassIcon);
