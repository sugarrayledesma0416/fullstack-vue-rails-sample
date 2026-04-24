import { LitElement, html } from 'lit';
import { ActionController } from '../../../controllers/action_controller';
import { IconCollection } from '../../../../entities/icon_collection';
import { sayItIcon } from './icons/say-it';
import { matchIcon } from './icons/match';
import { listenRepeatIcon } from './icons/listen-repeat';
import { diagnosticsIcon } from './icons/diagnostics';
import { interactiveVideoIcon } from './icons/interactive-video';
import { renderStyles } from './styles';

/** @typedef {import('lit').TemplateResult} Lit.TemplateResult */
/** @typedef {import('lit').CSSResult} Lit.CSSResult */
/** @typedef {import('lit').SVGTemplateResult} Lit.SVGTemplateResult */
/** @typedef {import('lit').PropertyDeclarations} Lit.PropertyDeclarations */
/** @typedef {import('../../../entities/action').Action} Action.Action */

/** Renders a single Intranav action in the Supersites theme. */
export class VHLIntranavSupersiteAction extends LitElement {
  /** @return {Lit.PropertyDeclarations} */
  static get properties() {
    return {
      action: {
        attribute: 'data-action',
        type: Object,
      },
      eventType: {
        attribute: 'data-event-type',
        type: String,
      },
    };
  }

  /** @return {Lit.CSSResult} */
  static get styles() {
    return renderStyles();
  }

  /** @constructor */
  constructor() {
    super();
    /** @type {Action.Action} */
    this.action;
    this.eventType = ActionController.DEFAULT_CLICK_EVENT_TYPE;
    this.controller = new ActionController(this);
    this.icons = new IconCollection(
      sayItIcon,
      matchIcon,
      listenRepeatIcon,
      diagnosticsIcon,
      interactiveVideoIcon);
  }

  /**
   * Renders a single Intranav action.
   *
   * @return {Lit.TemplateResult}
   */
  render() {
    const { name, label, state } = this.action;
    const srOnly = state !== 'current' ? 'u-screen-reader-only' : '';
    return html`
      <button
        type="button"
        ?disabled=${state === 'disabled'}
        @click=${() => this.controller.handleClick()}>
        <span class="icon">
          ${this.controller.renderIcon(name)}
        </span>
        <span lang="en" class="label ${srOnly}">${label}</span>
      </button>
    `;
  }
}

customElements.define(
  'vhl-intranav-supersite-action',
  VHLIntranavSupersiteAction
);

