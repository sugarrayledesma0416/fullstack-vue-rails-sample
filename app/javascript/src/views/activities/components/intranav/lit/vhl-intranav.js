import { LitElement, html, css } from 'lit';
import './themes/supersite';
import './themes/supersite_jr';

/** @typedef {import('lit').TemplateResult} Lit.TemplateResult */
/** @typedef {import('lit').CSSResult} Lit.CSSResult */
/** @typedef {import('lit').PropertyDeclarations} Lit.PropertyDeclarations */
/** @typedef {'supersites' | 'supersites_jr'} IntranavElement.Theme */

/**
 * A subnavigation for various activities.
 */
export class VHLIntranavElement extends LitElement {
  /**
   * Defines the component's properties.  These are derived from attributes
   * specified when the component is instantiated on the DOM.
   *
   * @return {Lit.PropertyDeclarations}
   */
  static get properties() {
    return {
      actions: {
        type: String,
        attribute: 'data-actions',
      },
      eventType: {
        type: String,
        attribute: 'data-event-type',
      },
      theme: {
        type: String,
        attribute: 'data-theme',
        converter: VHLIntranavElement.themeConverter,
        reflect: true,
      },
    };
  }

  /**
   * Converts the optional theme attribute into a local property.  Throws an
   * exception if an unsupported theme is supplied.  Defaults to "supersites".
   *
   * @param {string | null} value - The theme with which to
   * render the component.
   * @return {IntranavElement.Theme} The theme by which to render.
   */
  static themeConverter(value) {
    switch (value) {
    case null:
      return 'supersite';
    case 'supersite':
      return 'supersite';
    case 'supersite_jr':
      return 'supersite_jr';
    default:
      throw new Error(`Received invalid theme attribute, got ${value}`);
    }
  }

  /** @constructor */
  constructor() {
    super();
    this.actions = '';
    /** @type {'supersite' | 'supersite_jr'} */
    this.theme = 'supersite';
  }

  /**
   * The CSS used by the component.
   *
   * @return {Lit.CSSResult}
   */
  static get styles() {
    return css`
      *, *::before, *::after {
        box-sizing: border-box;
      }
    `;
  }

  /**
   * Renders the HTML for the component as reflected by its current state.
   *
   * @return {Lit.TemplateResult}
   */
  render() {
    return html`
      ${this._resolveTheme()}
    `;
  }

  /**
   * Resolves the correct theme element to render.
   *
   * @return {Lit.TemplateResult}
   * @private
   */
  _resolveTheme() {
    switch (this.theme) {
    case 'supersite_jr':
      return html`
        <vhl-intranav-jr
          data-actions="${this.actions}"
          data-event-type="${this.eventType}">
        </vhl-intranav-jr>
      `;
    default:
      return html`
        <vhl-intranav-supersite
          data-actions="${this.actions}"
          data-event-type="${this.eventType}">
        </vhl-intranav-supersite>
      `;
    }
  }
}

customElements.define('vhl-intranav', VHLIntranavElement);

