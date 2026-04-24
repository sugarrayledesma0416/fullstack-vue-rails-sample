document.addEventListener(
  'DOMContentLoaded',
  () => {
    const targetContainer = document.querySelector('.js-activity-buttons-target');
    const sourceContainer = document.querySelector('.js-activity-buttons-source');

    if (!targetContainer || !sourceContainer) {
      return;
    }

    const buttonElms = sourceContainer.querySelectorAll('[data-button]');
    buttonElms.forEach((buttonElm) => {
      buttonElm.classList.remove(
        'c-button',
        'c-button--border',
        'c-button--footer',
        'c-button--jr-link'
      );
      buttonElm.classList.add('c-button-v3');

      if (buttonElm.classList.contains('c-button--primary')) {
        buttonElm.classList.remove('c-button--primary');
        buttonElm.classList.add('c-button-v3--secondary');
      } else if (buttonElm.classList.contains('c-button--jr-primary')) {
        buttonElm.classList.remove('c-button--jr-primary');
        buttonElm.classList.add('c-button-v3--secondary');
      } else {
        buttonElm.classList.add('c-button-v3--tertiary');
      }

      targetContainer.appendChild(buttonElm);
      const space = document.createElement('text');
      space.textContent = ' ';
      targetContainer.appendChild(space);
    });
  }
);
