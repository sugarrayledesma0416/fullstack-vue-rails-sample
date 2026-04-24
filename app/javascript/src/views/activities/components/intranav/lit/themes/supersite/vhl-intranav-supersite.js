import { LitElement, html } from 'lit';
import { IntranavController } from '../../controllers/intranav_controller';
import { renderStyles } from './styles';
import './vhl-intranav-supersite-action';

/** @typedef {import('lit').TemplateResult} Lit.TemplateResult */
/** @typedef {import('lit').CSSResult} Lit.CSSResult */
/** @typedef {import('lit').PropertyDeclarations} Lit.PropertyDeclarations */
/** @typedef {import('lit').SVGTemplateResult} Lit.SVGTemplateResult */
/** @typedef {import('../../../entities/action').Action} Action.Action */
/** @typedef {import('../../../entities/action').Action.Name} Action.Name */

/** Renders and Intranav component with the Supersites theme. */
export class VHLIntranavSupersite extends LitElement {
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

  /** @return{Lit.CSSResult} */
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
   * Renders the intranav buttons.
   *
   * @return {Lit.TemplateResult}
   * @private
   */
  _renderActions() {
    const actions = this.actions.map((action) =>
      html`
        <vhl-intranav-supersite-action
          data-action="${JSON.stringify(action)}"
          data-event-type="${this.eventType}">
        </vhl-intranav-supersite-action>
      `);
    return html`${actions}`;
  }
}

customElements.define('vhl-intranav-supersite', VHLIntranavSupersite);

