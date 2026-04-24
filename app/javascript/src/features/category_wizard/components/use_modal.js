/**
 * This composable has methods that is related to the category modal.
 * @return {Function} addCircularNavigation
 */
const useModal = () => {
  /**
   * Add cyclic navigation support for TAB/ SHIFT+TAB keys
   * @param {HTMLElement} modal - Modal HTML Element.
   */
  function addCircularNavigation(modal) {
    modal.addEventListener('keydown', (event) => {
      const firstFocusElement = modal.querySelector('.js-modal-a11y__first-focus-element');
      const isTabPressed = (event.key === 'Tab' || event.keyCode === 9);
      if (!isTabPressed) {
        return;
      }

      const lastFocusElements = modal.querySelectorAll(
        '.js-modal-a11y__last-focus-element:not([disabled]'
      );
      const lastFocusElement = lastFocusElements[lastFocusElements.length - 1];

      if (event.shiftKey) {
        if (document.activeElement === firstFocusElement) {
          lastFocusElement.focus();
          event.preventDefault();
        }
      } else {
        if (document.activeElement === lastFocusElement) {
          firstFocusElement.focus();
          event.preventDefault();
        }
      }
    });
  }

  return { addCircularNavigation };
};

export default useModal;
