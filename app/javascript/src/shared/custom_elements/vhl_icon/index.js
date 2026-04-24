import { LitElement, css, html, unsafeCSS } from 'lit-element';

const iconSizeMapping = {
  'sm': '0.75rem',
  'md': '1rem',
  'md-lg': '1.25rem',
  'lg': '1.5rem',
  'xl': '2rem',
  'xxl': '4rem',
  'xxxl': '6rem',
};

const validSizes = Object.keys(iconSizeMapping);

/**
 * Generates a block of CSS for the icon element
 * @param {String} size - One of the named sizes (see iconSizeMapping)
 * @return {CSSResult}
 */
function spanStyle(size) {
  const val = unsafeCSS(iconSizeMapping[size]);

  return css`
    .c-vhl-icon.${ css`${unsafeCSS(size)}` } img {
      width: var(--vhl-icon-size, ${val});
      height: auto;
      line-height: 0;
    }
  `;
}

/**
 * Renders an Icon with a pre-set size
 *
 * @example
 * <vhl-icon
 *   path="/path/to/image.png"
 *   size="xxxl"
 * </vhl-icon>
 *
 * The following CSS variables can be used to customize the look and feel of
 * the icon:
 * --vhl-icon-size - The width of the icon (height scales proportionally).
 */
class Icon extends LitElement {
  /** @return {Properties} */
  static get properties() {
    return {
      path: {},
      size: {},
    };
  }

  /** @return {CSSResult} */
  static get styles() {
    const allStyles = validSizes.map((size) => spanStyle(size)).join('');

    return css`
      ${unsafeCSS(allStyles)}
    `;
  }

  /** @return {TemplateResult} */
  render() {
    if (this.size === undefined) {
      this.size = 'md';
    }

    if (!validSizes.includes(this.size)) {
      throw `size="${this.size}" is not a valid setting.`;
    }

    return html`
    <span class="c-vhl-icon  ${this.size}">
      <img aria-hidden="true" src="${ this.path }"></img>
    </span>
    `;
  }
}

export default Icon;
