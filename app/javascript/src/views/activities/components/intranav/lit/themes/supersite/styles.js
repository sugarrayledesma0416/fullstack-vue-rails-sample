import { css } from 'lit';

/** @typedef {import('lit').CSSResult} Lit.CSSResult */

/** @return {Lit.CSSResult} */
export function renderStyles() {
  return css`
    *, *::before, *::after {
      box-sizing: border-box;
    }

    .root {
      align-items: stretch;
      background-color: #eee;
      border-bottom-right-radius: 1rem;
      border-top-right-radius: 1rem;
      display: inline-flex;
      margin-left: -2rem;
      padding: 0 1rem 0 2rem;
    }
  `;
}

