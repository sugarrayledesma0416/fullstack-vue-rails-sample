const enableVtextLink = () => {
  document.querySelectorAll('[data-link-type]').forEach((elm) => {
    if (elm.dataset.linkType === 'vtext') {
      elm.removeAttribute('disabled');
    }
  });
};

const disableVtextLink = () => {
  document.querySelectorAll('[data-link-type]').forEach((elm) => {
    if (elm.dataset.linkType === 'vtext') {
      elm.setAttribute('disabled', 'disabled');
    }
  });
};

const clearForReview = () => {
  document.querySelectorAll('.flagged_for_review').forEach((elm) => {
    elm.classList.remove('flagged_for_review');
  });
};

const setRequestModeBodyClass = (requestMode) => {
  document.body.classList.remove(
    'report_problem_mode', 'report_content_mode', 'help_request_mode'
  );

  if (requestMode == 'request_help') {
    document.body.classList.add('help_request_mode');
  } else if (requestMode == 'request_review') {
    document.body.classList.add('help_request_mode');
  } else if (requestMode == 'report_technical_problem') {
    document.body.classList.add('report_problem_mode');
  } else if (requestMode == 'report_content_problem') {
    document.body.classList.add('report_content_mode');
  }
};

/**
 * Used to determine if an activity submit button is disabled.
 * @param {HTMLElement} submitButton
 * @return {Boolean}
 */
const alreadySubmitDisabled = (submitButton) => {
  return (submitButton.getAttribute('disabled') === 'disabled');
};

const updateSaveSubmitInDefaultMode = (submitBtn, saveBtn, helpableBlocks) => {
  // only enable the button if it wasn't disabled in the first place
  // pchat and vchat explicitly disable things
  if (!window.submitAlreadyDisabled) {
    submitBtn?.classList.remove('disabled-button');
  }
  saveBtn?.classList.remove('disabled-button');
  
  if (helpableBlocks) {
    helpableBlocks.forEach((elm) => {
      elm.classList.add('hidden_helper');
    });
  }
};

const updateSaveSubmitInNonDefaultMode = (submitBtn, saveBtn, helpableBlocks) => {
  // We need to save the state enabled/disabled for submit (pchat and vchat)
  // so that we put it back the way we found it.
  if (submitBtn?.getAttribute('disabled') === 'disabled') {
    window.submitAlreadyDisabled = true;
  } else {
    submitBtn?.classList.add('disabled-button');
  }
  saveBtn?.classList.add('disabled-button');

  if (helpableBlocks) {
    helpableBlocks.forEach((elm) => {
      elm.classList.remove('hidden_helper');
    });
  }
};


/**
 * Check the states of save and submit button.
 * @param {string} requestMode
 */
const updateSaveSubmit = (requestMode) => {
  const submitBtn = document.querySelector('.js-activity-submit');
  const saveBtn = document.querySelector('.js-activity-save');
  const footer = document.querySelector('.js-activity-footer');
  const helpableBlocks = footer?.querySelectorAll('.helpable_block');

  if (requestMode === 'default') {
    updateSaveSubmitInDefaultMode(submitBtn, saveBtn, helpableBlocks);
  } else {
    updateSaveSubmitInNonDefaultMode(submitBtn, saveBtn, helpableBlocks);
  }
};

export {
  enableVtextLink, disableVtextLink, clearForReview,
  setRequestModeBodyClass, alreadySubmitDisabled, updateSaveSubmit,
};
