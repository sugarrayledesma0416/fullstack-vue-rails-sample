import { LitElement, html } from 'lit';
import { renderStyles } from './styles';
import './vhl-intranav-jr-action';
import { IntranavController } from '../../controllers/intranav_controller';

/** @typedef {import('lit').TemplateResult} Lit.TemplateResult */
/** @typedef {import('lit').CSSResult} Lit.CSSResult */
/** @typedef {import('lit').PropertyDeclarations} Lit.PropertyDeclarations */
/** @typedef {import('../../../entities/action').Action} Action.Action */

/** Renders and Intranav with the Supersites Jr theme. */
export class VHLIntranavJR extends LitElement {
  /** @return {Lit.PropertyDeclarations} */
  static get properties() {
    return {
      actions: {
        attribute: 'data-actions',
        type: Array,
        converter: IntranavController.actionsConverter,
      },
      eventType: {
        attribute: 'data-event-type',
        type: String,
      },
    };
  }

  /** @constructor */
  constructor() {
    super();
    /** @type {Array<Action.Action>} */
    this.actions = [];
    this.eventType = '';
  }

  /** @return {Lit.CSSResult} */
  static get styles() {
    return renderStyles();
  }

  /** @return {Lit.TemplateResult} */
  render() {
    return html`
      <div class="root">
        ${this._renderActions()}
      </div>
    `;
  }

  /**
   * @return {Lit.TemplateResult}
   * @private
   */
  _renderActions() {
    const renderedActions = this.actions.map((action, index) => {
      return this._renderAction(action, index);
    });

    return html`
      <div class="actions">
        ${renderedActions}
      </div>
    `;
  }

  /**
   * Renders a single action.
   *
   * @param {Action.Action} action - The Action by which to render.
   * @param {number} index - The array index of the Action amongst the
   * others.
   * @return {Lit.TemplateResult}
   * @private
   */
  _renderAction(action, index) {
    const isLastAction = index === this.actions.length - 1;
    return html`
      <div class="action">
        <vhl-intranav-jr-action
          data-action="${JSON.stringify(action)}"
          data-event-type="${this.eventType}"
          ?data-icon-only=${isLastAction && action.state !== 'current'}
        </vhl-intranav-jr-action>
      </div>
    `;
  }
}

customElements.define('vhl-intranav-jr', VHLIntranavJR);

