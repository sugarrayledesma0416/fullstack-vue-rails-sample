const elmFromString = (string) => {
  const html = new DOMParser().parseFromString(string, 'text/html');
  return html.body.firstChild;
};

const getHtmlDocument = (domStr) => {
  const html = new DOMParser().parseFromString(domStr, 'text/html');
  return html;
};

export { elmFromString, getHtmlDocument };
