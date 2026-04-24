// @ts-check

import { LitElement, html } from 'lit-element';
import { ifDefined } from 'lit-html/directives/if-defined';
import { styles } from './styles';
import { RETURN_ICON } from './return_icon';

/** @typedef {import('lit-element').TemplateResult} TemplateResult */
/** @typedef {import('lit-element').CSSResult} CSSResult */

/**
 * Renders a stylized "return" link.
 *
 * NOTE: At the time of this writing, this was the only use case for this
 * particular style of link.  If more links/buttons appear with this style,
 * consider using this as a base for a more generalized version.
 *
 * @example
 * <vhl-return-link
 *   href="www.google.com"
 *   arialabel="Go to google."
 *   linktestclass="test-return-link">
 *   Return
 * </vhl-return-link>
 *
 * The following CSS variables can be used to customize the look and feel of
 * these styles:
 * --vhl-return-link-color - The color of the text and icon.
 * --vhl-return-link-hover-color - Text and icon colors when the link is
 *   hovered or focused.
 * --vhl-return-link-active-color - Text and icon color when the link is
 *   active or pressed.
 * --vhl-return-link-font-size - The font size of the label.
 * --vhl-return-link-padding - The link's overall padding.
 * --vhl-return-link-background-color - The link's background color.
 * --vhl-return-link-background-hover-color - The color of the link's
 *   background when focused or hovered over.
 * --vhl-return-link-icon-margin - The space between the icon and label text.
 * --vhl-return-link-icon-size - The width and height of the icon.
 * --vhl-return-link-icon-display - The icon's display property.
 */
export class VhlReturnLink extends LitElement {
  /** @return {Properties} */
  static get properties() {
    return {
      href: { type: String },
      arialabel: { type: String },
      linktestclass: { type: String },
    };
  }

  /**
   * @typedef Properties
   *
   * @property {HrefAttribute} href - (Optional) Appears as the link's
   * "href" attribute.
   *
   * @property {AriaLabelAttribute} arialabel - (Optional) Appears as the
   * link's "aria-label" attribute.
   *
   * @property {LinkTestClassAttribute} linktestclass - (Optional) Appears as
   * a test class on the actual link.
   */

  /**
   * @typedef HrefAttribute
   * @property {Href} type
   */

  /** @typedef {StringConstructor | undefined} Href */

  /**
   * @typedef AriaLabelAttribute
   * @property {AriaLabel} type
   */

  /** @typedef {StringConstructor | undefined} AriaLabel */

  /**
   * @typedef LinkTestClassAttribute
   * @property {LinkTestClass} type
   */

  /** @typedef {StringConstructor | undefined} LinkTestClass */

  /** @constructor */
  constructor() {
    super();
    /** @type {Href} */
    this.href;
    /** @type {AriaLabel} */
    this.arialabel;
    /** @type {LinkTestClass} */
    this.linktestclass;
  }

  /** @return {CSSResult} */
  static get styles() {
    return styles();
  }

  /** @return {TemplateResult} */
  render() {
    return html`
      <a
        href=${ifDefined(this.href ?? this.href)}
        aria-label=${ifDefined(this.arialabel ?? this.arialabel)}
        class=${ifDefined(this.linktestclass ?? this.linktestclass)}
      >
        <span class="icon">
          ${RETURN_ICON}
        </span>
        <span class="text">
          <slot></slot>
        </span>
      </a>
    `;
  }
}

