import { putToEndpoint } from 'shared/ajax_utils';
import { metaTagContent } from 'shared/utils.js';
import ENDPOINTS from './endpoints';

/**
 * @typedef {Object} Options
 * @property {boolean} [isMocked] - Whether to use the mock server.
 */

/**
 * Sends a PUT request saving the instructor's preference for toggling AI suggestions.
 * @param {boolean} toggleValue - The value to toggle the suggestions to.
 * @param {Options} [options] - Options to use for the request.
 * @return {Promise<boolean>} A resolved promise with the response data.
 */
export async function toggleAIGradingSuggestions(toggleValue, options = {}) {
  const opts = {
    isMocked: false,
    ...options,
  };

  if (opts.isMocked) {
    return await makeMockRequest(toggleValue);
  } else {
    return await makeRequest(toggleValue);
  }
}

/**
 * Returns a resolved promise with the value of the provided toggle.  This method is intended for
 * debugging purposes only.
 * @param {boolean} toggleValue
 * @return {Promise<boolean>}
 */
async function makeMockRequest(toggleValue) {
  return new Promise((resolve) => {
    resolve(toggleValue);
  });
}

/**
 * @template T
 * @typedef {ToggleResponse} Instructor
 * @property {T} response
 * @property {boolean} toggleValue
 */

/**
 * @param {boolean} toggleValue
 * @return {Promise<ToggleResponse>}
 */
async function makeRequest(toggleValue) {
  const result = await new Promise((resolve, reject) => {
    putToEndpoint(
      ENDPOINTS.INSTRUCTOR_UPDATE_AI_GRADING_SUGGESTIONS_SETTINGS,
      makePayload(toggleValue),
      (response) => {
        if (response.errors) reject(response.errors);
        resolve({ response: response, toggleValue });
      }
    );
  });
  return result;
}

/**
 * @typedef {Object} Payload
 * @property {Instructor} instructor

/**
 * @typedef {InstructorOptions} InstructorOptions
 * @property {string} enable_ai_grading_suggestions
 */

/**
 * @param {boolean} toggleValue
 * @return {Payload}
 */
function makePayload(toggleValue) {
  const sectionId = metaTagContent('VHL.section_id');
  return {
    instructor: {
      enable_ai_grading_suggestions: toggleValue.toString(),
    },
    section_id: sectionId,
  };
}
