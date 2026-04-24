import { metaTagContent } from './utils.js';

function getHeaders() {
  let headers = { 'Content-Type': 'application/json' };
  let csrfMetaContent = metaTagContent('csrf-token');
  if (csrfMetaContent !== undefined) {
    Object.assign(
      headers,
      { 'X-CSRF-Token': csrfMetaContent }
    );
  }

  return headers;
}

function getSettings(method, data) {
  let settings = { method: method,
                   credentials: 'include',
                   headers: getHeaders() };

  if (['POST', 'PUT'].includes(method)) {
    Object.assign(
      settings,
      { body: JSON.stringify(data) }
    );
  }

  return settings;
}

function makeFetchRequest(url, method, callback, data = {}) {
  fetch(url, getSettings(method, data))
    .then(async (resp) => {
      try {
        return await resp.json();
      } catch (error) {
        return resp;
      }
    })
    .then(callback);
}

const getFromEndpoint = (url, callback) => {
  makeFetchRequest(url, 'GET', callback);
};

const deleteFromEndpoint = (url, callback = () => {}) => {
  makeFetchRequest(url, 'DELETE', callback);
}

const postToEndpoint = (url, data, callback) => {
  makeFetchRequest(url, 'POST', callback, data);
}

const putToEndpoint = (url, data, callback) => {
  makeFetchRequest(url, 'PUT', callback, data);
}

/**
 * Gets the data from the endpoint with Accept Header.
 * @param {string} url - Get Request URL.
 * @param {Function} callback - Callback function to be executed after endpoint response.
 */
function getWithAcceptHeaders(url, callback) {
  const headersWithAccept = Object.assign(
    getHeaders(),
    { 'Accept': 'application/json' }
  );
  delete headersWithAccept['Content-Type'];

  const settings = {
    method: 'GET',
    credentials: 'include',
    headers: headersWithAccept,
  };
  fetch(url, settings)
    .then(async (resp) => {
      try {
        return await resp.json();
      } catch (error) {
        return resp;
      }
    })
    .then(callback);
}

export {
  deleteFromEndpoint,
  getFromEndpoint,
  getWithAcceptHeaders,
  postToEndpoint,
  putToEndpoint,
};
