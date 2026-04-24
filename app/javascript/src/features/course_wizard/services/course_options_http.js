import * as ajaxUtils from 'shared/ajax_utils';

/**
 * Get course options information from the server
 * @return {Promise} promise that resolve to course options info.
 */
const getCourseOptions = () => {
  const url = location.href.replace(/\??#.*/, '') + '.json';
  return new Promise((resolve) => {
    ajaxUtils.getFromEndpoint(
      url,
      (data) => {
        resolve(data);
      }
    );
  });
};

export default getCourseOptions;
