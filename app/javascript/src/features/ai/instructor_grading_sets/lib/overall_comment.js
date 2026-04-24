// @ts-check

/**
 * @typedef {Object} OverallCommentLike
 * @property {Function} accept
 * @property {boolean} accepted
 * @property {string} defaultComment
 * @property {boolean} edited
 * @property {Function} remove
 * @property {Function} validateEdit
 */

/**
 * @typedef {Object} AcceptOverallCommentOptions
 * @property {Function} callback - Called after the comment has been added.
 * @property {Document} DOM - An document object model for running queries against.  Defaults to
 * the browser's document object.  This option is provided for testing purposes.
 */

/**
  * Add the specified overall comment to the instructor comment.
  * @param {OverallCommentLike} overallComment
  * @param {string} overallCommentElmId
  * @param {Partial<AcceptOverallCommentOptions>} [options] - Optional parameters, including
  * dependency injection for testing.
  */
export function acceptOverallComment(overallComment, overallCommentElmId, options = {}) {
  const { DOM = document, callback = null } = options;
  const instructorCommentElm = DOM.getElementById(overallCommentElmId);

  if (instructorCommentElm instanceof HTMLTextAreaElement) {
    const defaultComment = overallComment.defaultComment;
    const currentComment = instructorCommentElm.value;
    const resultingComment = resolveCommentText(currentComment, defaultComment);
    instructorCommentElm.value = resultingComment;
    if (callback) callback();
  }
}

/**
 * If the user has made an addition to the default comment, returns the edited version.  Else
 * returns the default comment.
 * @param {string} currentComment
 * @param {string} defaultComment
 * @return {string}
 */
function resolveCommentText(currentComment, defaultComment) {
  let result = defaultComment;

  if (currentComment.includes(defaultComment)) {
    return currentComment;
  }
  
  if (currentComment.trim().length > 0) {
    result = `${currentComment.trim()}\n\n${defaultComment}`;
  }
  return result;
}

/**
 * @typedef {Object} RemoveOverallCommentOptions
 * @property {Function} callback - Called after the comment has been removed.
 * @property {Document} DOM - An document object model for running queries against.  Defaults to
 * the browser's document object.  This option is provided for testing purposes.
 */

/**
 * Remove the specified overall comment from the instructor comment.
 * @param {OverallCommentLike} overallComment
 * @param {string} overallCommentElmId
 * @param {Partial<RemoveOverallCommentOptions>} [options] - Optional parameters, including
 * dependency injection for testing.
 */
export function removeOverallComment(overallComment, overallCommentElmId, options = {}) {
  const { DOM = document, callback = null } = options;
  const instructorCommentElm = DOM.getElementById(overallCommentElmId);

  if (instructorCommentElm instanceof HTMLTextAreaElement) {
    const currentComment = instructorCommentElm.value;
    const newComment = currentComment.replace(overallComment.defaultComment, '');
    instructorCommentElm.value = newComment;
    if (callback) callback();
  }
}

/**
 * @typedef {Object} SetupOverallCommentInteropOptions
 * @property {Document} DOM
 */

/**
 * Sets up the interoperation between the overall comment box in the DOM and the provided
 * OverallComment object used by the Vue app.
 * @param {OverallCommentLike} overallComment
 * @param {string} overallCommentElmId,
 * @param {Partial<SetupOverallCommentInteropOptions>} [options] - Optional parameters, including
 * dependency injection for testing.
 */
export function setupOverallCommentInterop(overallComment, overallCommentElmId, options = {}) {
  const { DOM = document } = options;
  const instructorCommentElm = DOM.getElementById(overallCommentElmId);
  if (instructorCommentElm instanceof HTMLTextAreaElement) {
    instructorCommentElm.addEventListener(
      'input',
      /** @param {InputEvent} event */
      (event) => {
        if (event.target instanceof HTMLTextAreaElement && overallComment.accepted) {
          overallComment.validateEdit(event.target.value);
        }
      }
    );
  }
}
