import { css } from 'lit';

/** @typedef {import('lit').CSSResult} Lit.CSSResult */

/** @return {Lit.CSSResult} */
export function renderStyles() {
  return css`
    *, *::before, *::after {
      box-sizing: border-box;
    }

    .root {
      /*
       * Provides a buffer for the drop shadow effect that appears when action
       * buttons are hovered or focused.  This prevents a "cutoff" effect that
       * appears when the Intranav's scroll bar is present.
       */
      padding: 0.3rem;
    }

    .actions {
      align-items: center;
      display: flex;
    }

    .action {
      display: inline-block;
    }
    .action:not(:first-of-type) {
      margin-left: -1rem;
    }
  `;
}

