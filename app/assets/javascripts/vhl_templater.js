/**
 * Templater - a wrapper for Handlebars templating engine.
 *
 * Has been confirmed to work with Handlebars versions 1 & 4.
 */
VHL.Templater = (function() {

  /**
   * Merge the data with the template string.
   *
   * @param  {object} data             Data object to be merged
   * @param  {String} template         The template.
   * @return {string}                  String of markup with data merged in
   */
  function _render(data, template) {
    var templateFunction = Handlebars.compile(template);
    return templateFunction(data);
  }

  /**
   * Get markup of rendered template as a string
   *
   * @param  {Object} data   The data for the template
   * @param  {String} template  The template.
   * @return {string}           The rendered markup.
   */
  function get(data, template) {
    return _render(data, template);
  }

  /**
   * Render a template with some data and put the result in a destination element.
   * 
   * @public
   * @param {Object} data The data that will populate the template
   * @param {String} templateSelector Selector for the element from which to retrieve the template markup
   * @param {String} destinationSelector Selector for the element into which the result will be inserted.
   * @returns {Element} The destination element, to allow chaining.
   */
  function put(data, templateSelector, destinationSelector) {
    const templateEl = document.querySelector(templateSelector);
    const destinationEl = document.querySelector(destinationSelector);
    destinationEl.innerHTML = _render(data, templateEl.innerHTML);
    return destinationEl;
  }

  // Public methods:
  return { get, put };
})();
