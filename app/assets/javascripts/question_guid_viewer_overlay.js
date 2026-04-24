(() => {

  /**
   * Create html element with given tag, add style and css classes to it.
   * @param {string} tag
   * @param {Array.<string>} classNames
   * @param {object<string, string>} style
   * @return {HTMLElement}
   */
  function createElement(tag, classNames, style = null) {
    const el = document.createElement(tag);
    if (style) {
      el.style.cssText = style;
    }
    classNames.forEach(cls => el.classList.add(cls));
    return el;
  };

  /**
   * Create a backdrop so that user can not interact with the page content.
   */
  function createBackdropOverlay() {
    const backdrop = createElement('div', ['guid-viewer__backdrop', 'js-question-guid-layout-backdrop']);
    document.body.appendChild(backdrop);
  };

  /**
   * Show semi transparent overlay for each question
   * and add copy button to it.
   * @param {HTMLElement} el Question item element
   * @param {string} guid Question guid value
   */
  function createOverlay(el, guid) {
    const rect = el.getBoundingClientRect();
    const overlay = createElement('div', ['guid-viewer__overlay'], `
      top: ${window.scrollY + rect.top}px;
      left: ${window.scrollX + rect.left}px;
      width: ${rect.width}px;
      height: ${rect.height}px;
    `);

    let btn;
    if (!guid) {
      btn = createElement('button', ['guid-viewer__no-guid-btn', 'js-question-guid-copy']);
      btn.textContent = 'Question GUID value is empty';
    } else {
      btn = createElement('button', ['guid-viewer__copy-btn', 'js-question-guid-copy']);
      btn.textContent = `Copy GUID (${guid})`;
      btn.onclick = (evt) => onCopy(evt, guid);
    }

    overlay.appendChild(btn);
    document.body.appendChild(overlay);
  };

  /**
   * Show title to highlight the special mode.
   */
  function createHeaderOverlay() {
    const overlay = createElement('div', ['guid-viewer__header-overlay']);
    const span = document.createElement('span');
    span.textContent = 'QUESTION GUID VIEWER mode activated!';
    overlay.appendChild(span);
    document.body.appendChild(overlay);
  };

  /**
   * Show info message when there is no elements with guid attribute on the page.
   */
  function createMsgOverlay() {
    const msgOverlay = createElement('div', 'guid-viewer__msg-overlay');
    const span = document.createElement('span');
    span.textContent = 'We could not find any element on this page with data-question-guid attribute.';
    msgOverlay.appendChild(span);
    document.body.appendChild(msgOverlay);
  };

  /**
   * Copy the guid to clipboard
   * @param {Event} evt
   * @param {string} guid Question guid value
   */
  function onCopy(evt, guid) {
    evt.stopPropagation();
    const btn = evt.currentTarget;

    navigator.clipboard.writeText(guid).then(() => {
      btn.textContent = 'Copied GUID!';
      setTimeout(() => {
        btn.textContent = `Copy GUID (${guid})`;
      }, 1000);
    });
  };

  /**
   * Show semi transparent overlay for each html element
   * which has data-question-guid attribute value present.
   */
  function showQuestionGuidOverlays() {
    const elements = document.querySelectorAll('[data-question-guid]');

    if (elements.length === 0) {
      createMsgOverlay();
      return;
    }

    elements.forEach(el => {
      const guid = el.getAttribute('data-question-guid');
      createOverlay(el, guid);
    });

    addCircularNavigation();
  };

  /**
   * Add cyclic navigation support for TAB/ SHIFT+TAB keys
   */
  function addCircularNavigation() {
    const buttons = document.querySelectorAll('.js-question-guid-copy');
    if (!buttons.length) return;

    const first = buttons[0];
    const last = buttons[buttons.length - 1];

    first.focus();

    document.addEventListener('keydown', e => {
      if (e.key !== 'Tab') return;

      if (e.shiftKey && document.activeElement === first) {
        last.focus();
        e.preventDefault();
      } else if (!e.shiftKey && document.activeElement === last) {
        first.focus();
        e.preventDefault();
      }
    });
  };

  /**
   * This is main method to activate Question Guid Viewer mode.
   * Turn on question guid viewer feature with a timeout so that page content is settled by then.
   * But create backdrop immediately to prevent user action on page content.
   */
  function turnOnQuestionGuidViewer() {
    createBackdropOverlay();
    createHeaderOverlay();
    setTimeout(showQuestionGuidOverlays, 2000);
  };

  // Run on page load
  document.readyState === 'loading'
    ? document.addEventListener('DOMContentLoaded', turnOnQuestionGuidViewer)
    : turnOnQuestionGuidViewer();
})();
