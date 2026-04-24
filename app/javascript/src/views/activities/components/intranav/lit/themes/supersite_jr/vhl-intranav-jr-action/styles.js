import { css } from 'lit';

/** @typedef {import('lit').CSSResult} Lit.CSSResult */

/** @return {Lit.CSSResult} */
export function renderStyles() {
  const clickHighlight = css`0 0 0 0.1rem #acf`;
  return css`
    *, *::before, *::after {
      box-sizing: border-box;
    }

    :host {
      display: flex;
      flex-wrap: no-wrap;
      flex-shrink: 0;
    }

    button {
      align-items: center;
      background: transparent;
      border: 0;
      border-radius: 0;
      cursor: pointer;
      display: inline-flex;
      outline: 0;
      padding: 0;
      position: relative;
    }
    button[disabled] {
      cursor: not-allowed;
    }

    .icon {
      border-radius: 50%;
      background-color: #eee;
      display: inline-block;
      height: 4rem;
      margin-right: -1rem;
      overflow: hidden;
      width: 4rem;
      z-index: 2;
    }
    .button--current .icon {
      background-color: #fefcef;
    }
    .button--navigable .icon {
      background-color: white;
    }

    .icon-backdrop {
      background-color: #0f0;
      border-radius: 50%;
      box-shadow: 0 0.2rem 0.2rem rgba(0, 0, 0, 0.15);
      display: block;
      height: 100%;
      position: absolute;
      width: 4rem;
      z-index: 1;
    }
    button[disabled] .icon-backdrop {
      display: none;
    }
    button:hover .icon-backdrop,
    button:focus .icon-backdrop {
      box-shadow:
        0 0 0 0.2rem #acf,
        0 0.2rem 0.2rem 0.1rem rgba(0, 0, 0, 0.15);
    }
    .button--navigable .icon-backdrop {
      box-shadow:
        ${clickHighlight},
        0 0.2rem 0.2rem 0.1rem rgba(0, 0, 0, 0.15);
    }

    .label {
      align-items: center;
      background-color: #fefcef;
      border-radius: 0.5rem;
      box-shadow: 0 0.2rem 0.2rem rgba(0, 0, 0, 0.15);
      display: inline-flex;
      flex-shrink: 0;
      font-family: Open Sans, Helvetica Neue, Helvetica, Arial, Sans-serif;
      height: auto;
      min-height: 2.8rem;
      padding: 0 3rem 0 0;
      z-index: 1;
    }
    .button--current .label {
      padding: 0 2rem;
    }
    .button--navigable .label {
      background-color: white;
      box-shadow:
        ${clickHighlight},
        0 0.2rem 0.2rem rgba(0, 0, 0, 0.15);
    }
    button:hover:not([disabled]) .label,
    button:focus .label {
      box-shadow:
        0 0 0 0.2rem #acf,
        0 0.2rem 0.2rem rgba(0, 0, 0, 0.15);
    }

    .label-text {
      display: inline-block;
      font-size: 1.2rem;
      line-height: 1;
      text-transform: uppercase;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    .u-screen-reader-only {
      border: 0 !important;
      clip: rect(0 0 0 0) !important;
      height: 1px !important;
      margin: -1px !important;
      overflow: hidden !important;
      padding: 0 !important;
      width: 1px !important;
    }

    svg {
      display: inline-block;
      height: 100%;
      max-width: 100%;
      width: auto;
    }
    button[disabled] svg {
      opacity: 0.5;
    }
  `;
}
