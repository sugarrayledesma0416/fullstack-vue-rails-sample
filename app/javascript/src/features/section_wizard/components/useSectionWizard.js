/**
 * This composable has methods for useSectionWizard.
 * @param {Object} datastore - Vue js reactive object to store app state
 * @return {Object}
 */
const useSectionWizard = (datastore) => {
  /**
   * Show Confirm Diaog on Page Leave.
   */
  const addConfirmEventListenerOnPageLeave = () => {
    window.addEventListener('beforeunload', function(e) {
      if (hasChanges() &&
        !datastore.section.saving &&
        !VHL.Common.shouldPreventWarningsAfterTimeout()) {
        e.preventDefault();
        const confirmationMessage = 'You have unsaved changes.' +
          'Are you sure you want to leave?';

        (e || window.event).returnValue = confirmationMessage; // Gecko + IE
        return confirmationMessage; // Gecko + Webkit, Safari, Chrome etc.
      }
    });
  };

  /**
   * @private
   * Check if section form has been updated.
   * @return {boolean} - whether section form has changes.
   */
  function hasChanges() {
    return datastore.initialData !== JSON.stringify(datastore.section);
  }

  return { addConfirmEventListenerOnPageLeave };
};

export default useSectionWizard;
