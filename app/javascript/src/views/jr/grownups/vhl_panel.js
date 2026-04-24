import { LitElement, css, html } from 'lit-element';

/**
 * Renders a panel with optional slots for header text, an icon shown in
 * the header, body, and footer.
 * Styling can be customized by passing in a "variant" attr. Currently
 * only the supersites=js variant is defined.
 *
 * @example
 * <vhl-panel variant="supersites-jr">
 *   <span slot="icon"><img src="my_icon.svg" /></span>
 *   <h2 slot="header">My Header</h2>
 *   <p slot="body">My Body</p>
 *   <div slot="footer">My footer contents</div>
 * </vhl-panel>
 */
export class VhlPanel extends LitElement {
  /** @return {Properties} */
  static get properties() {
    return {
      variant: { type: String },
    };
  }

  /** @return {CSSResult} */
  static get styles() {
    return css`
      .container {
        margin-bottom: 1rem;
        margin-left: 1rem;
        margin-right: 1rem;
      }

      .header {
        display: flex;
        font-weight: bold;
        line-height: 1.5rem;
        margin: 0;
        padding: 1rem 1.5rem 0.5rem;
      }

      .body {
        padding: 1rem 1rem 0.5rem;
      }

      .header ::slotted([slot=icon]) {
        margin-right: 0.5rem;
      }

      .header ::slotted([slot=header]) {
        font-size: 1.4rem !important;
      }

      @media screen and (max-width: 500px) {
        .header, .body {
          padding-left: 0.5rem;
          padding-right: 0.5rem;
        }

        .header ::slotted([slot=header]) {
          font-size: 1.1rem !important;
        }

        .header ::slotted([slot=icon]) {
          display: none;
        }
      }

      .supersites-jr .header {
        background-color: var(--ui-accent-color);
        border-top-left-radius: 1.8rem;
        border-top-right-radius: 1.8rem;
      }

      .supersites-jr .header ::slotted([slot=header]) {
        color: var(--ui-text-color, #000) !important;
      }

      .supersites-jr .body {
        background-color: var(--white, #fff);
        border-bottom-left-radius: 1.8rem;
        border-bottom-right-radius: 1.8rem;
      }

      div.supersites-jr {
        border-radius: 1.8rem;
        box-shadow: 0 0.0625rem 0.3rem rgba(0, 0, 0, 0.4);
      }
    `;
  }

  /** @constructor */
  constructor() {
    super();
  }

  /** @return {TemplateResult} */
  render() {
    return html`
      <div class="container  ${this.variant}">
        <div class="header">
          <slot name="icon"></slot>
          <slot name="header"></slot>
        </div>
        <div class="body">
          <slot name="body"></slot>
        </div>
        <div class="footer">
          <slot name="footer"></slot>
        </div>
      </div>
    `;
  }
}
