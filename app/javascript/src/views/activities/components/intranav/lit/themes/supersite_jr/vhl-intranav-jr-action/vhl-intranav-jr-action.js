import { LitElement, html } from 'lit';
import { ActionController } from '../../../controllers/action_controller';
import { renderStyles } from './styles';
import { IconCollection } from '../../../../entities/icon_collection';
import { diagnosticIcon } from './icons/diagnostic';
import { listenRepeatIcon } from './icons/listen-repeat';
import { matchIcon } from './icons/match';
import { sayItIcon } from './icons/say-it';
import { videoTutorialIcon } from './icons/video-tutorial';

/** @typedef {import('lit').TemplateResult} Lit.TemplateResult */
/** @typedef {import('lit').CSSResult} Lit.CSSResult */
/** @typedef {import('lit').SVGTemplateResult} Lit.SVGTemplateResult */
/** @typedef {import('lit').PropertyDeclarations} Lit.PropertyDeclarations */
/** @typedef {import('../../../entities/action').Action} Action.Action */

/** Renders a single Intranav action in the Supersites Junior theme. */
export class VHLIntranavJRAction extends LitElement {
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
      iconOnly: {
        attribute: 'data-icon-only',
        type: Boolean,
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
    this.iconOnly = false;
    /** @type {Action.Action} */
    this.action;
    this.arrayIndex = -1;
    this.eventType = ActionController.DEFAULT_CLICK_EVENT_TYPE;
    this.controller = new ActionController(this);
    this.icons = new IconCollection(
      sayItIcon,
      matchIcon,
      listenRepeatIcon,
      diagnosticIcon,
      videoTutorialIcon);
  }

  /** @return {Lit.TemplateResult} */
  render() {
    const { state, label, name } = this.action;
    const screenReaderFriendlyLabel =
      this.controller.formatStringForScreenReaders(label);
    const hideLabel = state !== 'current';
    return html`
      <button
        type="button"
        @click=${() => this.controller.handleClick()}
        ?disabled=${state === 'disabled'}
        class="button--${state}">
        <span class="icon-backdrop"></span>
        <span class="icon">
          ${this.controller.renderIcon(name)}
        </span>
        <span class="label ${this.iconOnly ? 'u-screen-reader-only' : ''}">
          <span
            lang="en"
            aria-label="${screenReaderFriendlyLabel}"
            class="label-text ${hideLabel ? 'u-screen-reader-only' : ''}">
            ${label}
          </span>
        </span>
      </button>
    `;
  }
}

customElements.define('vhl-intranav-jr-action', VHLIntranavJRAction);

