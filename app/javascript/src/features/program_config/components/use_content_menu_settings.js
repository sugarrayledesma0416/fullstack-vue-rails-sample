import * as ajaxUtils from 'shared/ajax_utils';

/**
 * This composable has methods for Content Menu Settings in Program Config.
 * @param {Object} props - Vue js props object.
 * @param {Object} dataStore - Vue js reactive object to store app state
 * for ContentMenuSettings component.
 * @return {Object} - An object wrapping following methods
 * addAdditionalEntry,
 * initialAdditionalEntries,
 * removeAdditionalEntry,
 * updateVocabTools,
 */
const useContentMenuSettings = (props, dataStore) => {
  /**
   * Get default additional entry object
   * @return {Object}
   */
  const getEmptyEntry = () => {
    return { label: '', programId: '', targetUser: 'Instructor', url: '', description: '' };
  };

  /**
   * Get value of additionalEntries to set in dataStore
   * @return {Object}
   */
  const initialAdditionalEntries = () => {
    return props.additionalEntries.length ?
      props.additionalEntries : [getEmptyEntry()];
  };

  /**
   * Set new additional entry in dataStore
   */
  const addAdditionalEntry = () => {
    dataStore.additionalEntries.push(getEmptyEntry());
  };

  /**
   * Remove additional entry from dataStore
   * @param {Object} payload - Payload  object from Additional Entry component
   * @param {number} payload.entryIndex - Index of additiona entry which is to be removed
   */
  const removeAdditionalEntry = (payload) => {
    const { entryIndex } = payload;
    dataStore.additionalEntries.splice(entryIndex, 1);
  };

  /**
   * Update VocabTools data for the program
   * Note: Currently, ajaxUtils.getFromEndpoint returns fetchResponse.json() and if any error is
   * caught while calling .json() on fetch response then it returns fetch response as is.
   * So explicitly checking 'response.ok === false' for error condition.
   */
  const updateVocabTools = () => {
    dataStore.vocabToolsStatus = 'Updating...';
    const updateUrl = '/programs/' + props.programId + '/update_vocab_tools';
    ajaxUtils.getFromEndpoint(
      updateUrl,
      (response) => {
        if (response.ok === false) {
          dataStore.vocabToolsStatus = 'Oops, something went wrong. Check the browser console.';
        } else {
          dataStore.vocabToolsStatus = 'Updated, check the program vocabulary.';
        }
      }
    );
  };

  return {
    addAdditionalEntry,
    initialAdditionalEntries,
    removeAdditionalEntry,
    updateVocabTools,
  };
};

export default useContentMenuSettings;
