// @ts-check

import { css } from 'lit-element';

/** @typedef {import('lit-element').CSSResult} CSSResult */

/**
 * The following CSS variables can be used to customize the look and feel of
 * these styles:
 * --vhl-return-link-color - The color of the text and icon.
 * --vhl-return-link-hover-color - Text and icon colors when the link is
 *   hovered or focused.
 * --vhl-return-link-active-color - Text and icon color when the link is
 *   active or pressed.
 * --vhl-return-link-font-size - The font size of the label.
 * --vhl-return-link-padding - The link's overall padding.
 * --vhl-return-link-background-color - The link's background color.
 * --vhl-return-link-background-hover-color - The color of the link's
 *   background when focused or hovered over.
 * --vhl-return-link-icon-margin - The space between the icon and label text.
 * --vhl-return-link-icon-size - The width and height of the icon.
 * --vhl-return-link-icon-display - The icon's display property.
 *
 * @return {CSSResult}
 */
export function styles() {
  const defaultColor = css`#527dea`;

  const color = css`var(--vhl-return-link-color, ${defaultColor})`;
  const hoverColor = css`var(--vhl-return-link-hover-color, ${defaultColor})`;
  const activeColor = css`var(--vhl-return-link-active-color, #0d3188)`;
  const size = css`var(--vhl-return-link-font-size, 1rem)`;

  const padding = css`var(--vhl-return-link-padding, 0.2rem 1.1rem 0.2rem 0.8rem)`;

  const bgColor = css`var(--vhl-return-link-background-color, #fff)`;
  const bgHoverColor = css`var(--vhl-return-link-background-hover-color, #f5f5f5)`;

  const iconMargin = css`var(--vhl-return-link-icon-margin, 0.8rem)`;
  const iconSize = css`var(--vhl-return-link-icon-size, 3rem)`;
  const iconDisplay = css`var(--vhl-return-link-icon-display, inline-block)`;

  return css`
    :host {
      display: inline-block;
    }

    a {
      display: flex;
      align-items: center;
      border-radius: 0.5rem;
      padding: ${padding};
      box-shadow: 0.1rem 0.1rem 0.4rem rgba(0, 0, 0, 0.3);
      background-color: ${bgColor};
      color: ${color};
      font-size: ${size};
      text-decoration: none;
      text-transform: uppercase;
    }

    a:hover, a:focus {
      cursor: pointer;
      color: ${hoverColor};
      background-color: ${bgHoverColor};
    }

    a:active {
      background-color: ${bgColor};
      color: ${activeColor};
      box-shadow: inset 0.0625rem 0.0625rem 0.3rem rgba(0, 0, 0, 0.4);
      background-color: var(--white);
    }

    .icon {
      display: ${iconDisplay};
      width: ${iconSize};
      height: ${iconSize};
      margin-right: ${iconMargin};
      fill: ${color};
    }

    a:hover .icon,
    a:focus .icon {
      fill: ${hoverColor};
    }

    a:active .icon {
      fill: ${activeColor};
    }

    .text {
      display: inline-block;
    }
  `;
}

