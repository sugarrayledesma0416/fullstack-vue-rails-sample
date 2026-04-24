/**
 * This composable provides methods related to accent bar component integration in modal
 * @param {VHL.AccentBarComponent} accentBarComponent vue ref for class instance
 * @param {HTMLElement} refModalContainerElm vue ref for parent elm of add request modal
 * @param {HTMLElement} refTextareaElm vue ref for comment textarea in add request modal
 * @return {Object} retruns object wrapping following methods
 * attachToAccentBarEvents,
 * detachFromAccentBarEvents,
 * moveAccentBarBackToActivity,
 * moveAccentBarToRequestModal,
 */
const useHelpRequestAccentBarHelper = (
  accentBarComponent,
  refModalContainerElm,
  refTextareaElm
) => {
  const accentBarEnabled = document.querySelector('meta[name="VHL.program_accent_bar_enabled"]')
    ?.content === 'true' || false;

  /**
  * Move Accent bar component modal from activity footer to help request modal
  * to manage the z-index issue. Registering the textarea here because
  * we need the accent bar instance to deactivate accent bar before closing request modal.
  */
  const moveAccentBarToRequestModal = () => {
    if (refTextareaElm.value && accentBarEnabled) {
      // Registering request modal textarea for accent bar
      accentBarComponent.value = new VHL.AccentBarComponent();
      accentBarComponent.value.register(refTextareaElm.value);
    }
    const accentBarActivityContainer = document.querySelector('.js-accent-bar-container--activity');
    const accentBarModalElement = accentBarActivityContainer?.querySelector('.js-accent-bar-modal');
    if (accentBarModalElement) {
      // Append accent bar in request dialog container DOM Element
      refModalContainerElm.value?.appendChild(accentBarModalElement);
    }
  };

  /**
  * Deactivate the accent bar on request modal and moves the
  * accent bar component element back to the activity footer.
  */
  const moveAccentBarBackToActivity = () => {
    // This request dialog container DOM Element has access bar dom
    const accentBarContainer = refModalContainerElm.value;
    const accentBarModalElement = accentBarContainer.querySelector('.js-accent-bar-modal');
    if (accentBarModalElement && accentBarComponent.value) {
      // First deactivate the active accent bar then move to the accent bar container in activity.
      accentBarComponent.value.deactivateAll();
      // move accent bar from request dialog container DOM Element.
      document.querySelector('.js-accent-bar-container--activity')?.append(accentBarModalElement);
    }
  };

  /**
  * Attach to accented_character_added event from accent bar to update propertyKey
  * as no input/change event is fired otherwise as AccentBar programmatically inserts characters.
  * @param {HTMLElement} textboxElement textarea elm in add request modal
  * @param {Object} requestDialogModel - reactive modal
  * @param {Object} propertyKey - ref value property
  */
  const attachToAccentBarEvents = (textboxElement, requestDialogModel, propertyKey) => {
    // listening to jquery event
    $(textboxElement).on('accented_character_added', () => {
      requestDialogModel[propertyKey] = textboxElement.value;
    });
  };

  /**
  * Cleaning code to detach accented_character_added event
  * @param {HTMLElement} textboxElement textarea elm in add request modal
  */
  const detachFromAccentBarEvents = (textboxElement) => {
    // detaching from jquery event
    $(textboxElement).off('accented_character_added');
  };

  return {
    attachToAccentBarEvents,
    detachFromAccentBarEvents,
    moveAccentBarBackToActivity,
    moveAccentBarToRequestModal,
  };
};

export default useHelpRequestAccentBarHelper;
