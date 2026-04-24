import { css } from 'lit';

/** @typedef {import('lit').CSSResult} Lit.CSSResult */

/** @return {Lit.CSSResult} */
export function renderStyles() {
  const hoverColor = css`#004b7a`;

  return css`
    *, *::before, *::after {
      box-sizing: border-box;
    }

    button {
      background: transparent;
      border: 0;
      border-radius: 0;
      color: #006bae;
      cursor: pointer;
      outline: 0.125rem solid transparent;
      outline-offset: 0.125rem;
      margin-right: 1rem;
      padding: 0;
      transition:
        color 0.2s ease-in-out,
        box-shadow 0.2s ease-in-out;
      white-space: nowrap;
    }
    button:hover:not([disabled]) {
      color: ${hoverColor};
    }
    button:focus {
      outline: 0.125rem solid;
      outline-color: #0091eb;
    }
    button[disabled] {
      color: #ccc;
      cursor: not-allowed;
    }

    .icon {
      background-color: #fff;
      border-radius: 0.1875rem;
      box-shadow: 1px 2px 4px 0 rgb(0 0 0 / 22%);
      display: inline-block;
      text-decoration: none;
      white-space: nowrap;
    }
    button[disabled] .icon {
      background-color: #ccc;
      box-shadow: none;
    }

    svg {
      background-size: 2rem 2rem;
      fill: #000;
      height: 2rem;
      line-height: 2rem;
      padding: 0.125rem;
      vertical-align: middle;
      width: 2rem;
    }
    button:hover:not([disabled]) svg,
    button:focus svg {
      fill: ${hoverColor};
    }
    button[disabled] svg {
      fill: #fff;
    }

    .label {
      color: #000;
      font-weight: bold;
      line-height: 2rem;
      vertical-align: middle;
      margin: 0 0.5rem;
    }
    button:hover:not([disabled]) .label,
    button:focus:not([disabled]) .label {
      color: ${hoverColor};
      text-decoration: underline;
    }

    .u-screen-reader-only {
      border: 0 !important;
      clip: rect(0 0 0 0) !important;
      height: 1px !important;
      margin: -1px !important;
      overflow: hidden !important;
      padding: 0 !important;
      position: absolute !important;
      width: 1px !important;
    }
  `;
}

