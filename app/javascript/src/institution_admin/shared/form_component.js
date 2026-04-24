/**
 * Create an iterable of callbacks that instantiate components.
 * Run them in parallel and resolve when all are done.
 * @summary Instantiate all components, then resolve.
 * @param {Object} elmsByClassName - mapping of component class name to elm list
 * @param {Promise} callback - async method that instantiates the components
 * @returns {Promise} a promise that resolves when all callbacks have resolved
 */
async function buildComponentsInParallel(elmsByClassName, callback) {
  await Promise.all(
    Object.entries(elmsByClassName).map(
      ([className, elms]) => callback(className, elms)
    )
  );
}

/**
 * @summary Extract component name from an element.
 * @param {HTMLElement} elm - a component root element
 * @param {Function} transform - callback that transforms component name.
 * @returns {String} result of transform
 */
function getComponentName(elm, transform) {
  // Find the elm's CSS class that matches the form-component regex.
  let cssClass = [...elm.classList].find(s => /^js-form-component--/.test(s));

  // Isolate everything after the '--', split it into tokens,
  //   and add 'component' to the tokens.
  let componentNameStart = cssClass.split('--')[1];
  let tokens = [...componentNameStart.split('-'), 'component'];

  // Transform the tokens.
  return `${transform(tokens)}`;
}

/**
 * Find an element's component class name from its CSS class.
 * Given a component class named CamelCaseComponent, the convention for
 * its corresponding CSS class is:
 *
 *   js-form-component--camel-case
 *
 * I.e., remove 'Component' from the class name, divide the name into tokens
 * so that each capital letter begins a token, lower-case the tokens, and join
 * with '-'.
 *
 * This function reverses that transformation.
 *
 * @summary Retrieve a component class name based on an element's CSS class.
 * @param {HTMLElement} elm - the root element of the component
 * @returns {String} the name of the component class
 */
function getComponentClassName(elm) {
  return getComponentName(
    elm,
    /**
     * The transform function capitalizes the first char of each token
     * and joins the tokens.
     */
    (tokens) => {
      return tokens.map((s) => {
        return `${s[0].toUpperCase()}${s.slice(1)}`;
      }).join('');
    }
  );
}

/**
 * @summary Retrieve component class filename from element.
 * @param {HTMLElement} elm - the root element of the component
 * @returns {String} the filename for the element's component class
 */
function getComponentFilePath(elm) {
  let path = elm.dataset.path;

  return getComponentName(
    elm,
    /**
     * The transform function snake-cases the tokens.
     */
    (tokens) => {
      return `${path}/${tokens.join('_')}`;
    }
  );
}

/**
 * Convert class name to lowercase plural.
 * @param {String} string - a class name, assumed to be capitalized and singular
 * @returns {String} the string with first character lowercase and 's' appended
 */
function lowerCasePlural(string) {
  return `${string[0].toLowerCase()}${string.slice(1)}s`;
}

/**
 * The intent of FormComponent is to provide a base class that will let us
 * write form code in terms of components that follow a predictable pattern
 * and that may be composed into arbitrarily complex form objects.
 * @summary Base class for composable form components.
 */
class FormComponent {
  /**
   * Create and initialize a form component.
   * @param {HTMLElement} rootElm - the element that will contain the component.
   * @param {Object} config - a configuration object that may contain
   *   `context` - an object containing state for template rendering
   *   `elmEventListenerMap` - an object mapping CSS class to an event and
   *                           handler
   */
  constructor(rootElm, config = {}) {
    this.rootElm = rootElm;
    this.initialContext = config.context || {};
    this.elmEventListenerMap = config.elmEventListenerMap || {};
    this.model = this.initialContext.model || {};
    this.subcomponentsToSkip = config.subcomponentsToSkip || [];

    this.init(this.initialContext);
  }

  /**
   * Find any subcomponents within the component, instantiate them, and store
   * them in arrays by component-class name. Because the subcomponents are also
   * form-component subclasses, this operation will recursively construct the
   * complete form object.
   *
   * A subcomponent will be instantiated if it follows this contract:
   *
   * 1. It must include exactly one CSS class of the form
   *    'js-form-component--[start of component class name]'.
   * 2. It must include a data-path attribute with the path to the component
   *    class's parent directory.
   * @summary Discover, instantiate, and store subcomponents.
   * @param {Object} context - an object containing state for template rendering
   */
  async buildFormComponentCollection(context) {
    // This object will map each component class name to instances of the class.
    let formComponents = {};

    // Build the subcomponents.
    await buildComponentsInParallel(this.elmsByComponentClassName(),
                                    async (className, elms) => {
      // Import the class dynamically.
      let classConstructor = (
        /**
         * Limit the scope of the dynamic import to the institution-admin dashboard parent
         * directory: the parent directory had been `src`, but we do not expect to use this
         * form-component code outside of the institution-admin feature.
         * Reducing the scope addresses a build error caused by Webpack trying to compile any
         * JS file under `src`, including code meant to be compiled by Vite only.
         */
        await import(`src/institution_admin/dashboard/${getComponentFilePath(elms[0])}.js`)
      )[className];

      // Instantiate an object for each elm in the list for the class.
      // Map the array of objects to the class name.
      formComponents[className] = elms.map(
        elm => new classConstructor(elm, context)
      );
    });

    /**
     * Assign the object lists as properties of this component instance.
     * The property name is the class name pluralized, e.g. an array of
     * FooComponent instances will be available as this.fooComponents.
     */
    for (let [key, value] of Object.entries(formComponents)) {
      this[lowerCasePlural(key)] = value;
    }
  }

  /**
   * @summary Return a mapping of component class name to an array of elements.
   * @returns {Object} an object of form { className: [elm1, elm2, ...] }
   */
  elmsByComponentClassName() {
    // get all child elements with js-form-component class
    let formComponentElms = this.rootElm.querySelectorAll(
      '[class^=js-form-component]'
    );

    return [...formComponentElms].reduce((h, elm) => {
      /**
       * Extract the component class name.
       * If we're supposed to skip building components of that class,
       * bail out early and return the accumulator unchanged.
       */
      let componentClassName = getComponentClassName(elm);
      if (this.skip(componentClassName)) { return h; }

      /**
       * Otherwise, modify the accumulator by adding the elm to the list of elms
       * for the class (first assigning an empty list if none exists yet).
       */
      return Object.assign(
        {},
        h,
        { [componentClassName]: (h[[componentClassName]] || []).concat(elm) }
      );
    }, {});
  }

  skip(className) {
    return this.subcomponentsToSkip.includes(className);
  }

  /**
   * Render the HTML for the component. This is intended for components that
   * are rendered client-side. A component that arrives fully rendered from
   * the server does not have to implement this method.
   *
   * In this PR, the component renders its HTML with a Handlebars template that
   * is named after it (e.g., FooComponent => fooTemplate) and stored in a
   * separate file (e.g. foo_component.js => foo_template.js).
   * @summary Render the HTML for the component.
   */
  draw() {
  }

  /**
   * Use the elmEventListenerMap to add event listeners.
   * The mapping is cssClass: [eventName, handler],
   * e.g. 'fc-submit-button': ['click', submitToEndpoint].
   * @summary Add event listeners to child elements.
   */
  addEventListeners() {
    const subclassObject = this;
    for (let [cssClass, evtArgs] of Object.entries(this.elmEventListenerMap)) {
      let [eventName, funcName] = evtArgs;

      /** Because the event-listener mapping is defined before the superclass
       *    constructor runs (i.e., before memory is allocated for the object),
       *    the handlers are passed in as strings that correspond to method
       *    names of the subclass.
       */
      this.getElms(cssClass).forEach(function(elm) {
        elm.addEventListener(
          eventName,
          subclassObject[funcName].bind(subclassObject)
        );
      });
    }
  }

  /**
   * Set up the component:
   *
   * 1. Render it (if it has not already been rendered server-side).
   * 2. Instantiate any subcomponents within it.
   * 3. Add any event listeners.
   *
   * Note: this method is called by the constructor, but it may also be called
   *       outside of the constructor to redraw the component.
   *
   * @summary Set up the component.
   * @param {Object} context - an object containing state for template rendering
   */
  async init(context={}) {
    this.initialized = false;
    await this.draw(context);

    // discover and instantiate child form components
    // stored in hash: key = class, value = array of objects
    await this.buildFormComponentCollection(context);

    this.addEventListeners();
    this.initialized = true;
  }

  confirmInitialization() {
    let formComponent = this;
    return new Promise((resolve) => {
      function waitForInitialization() {
        if (formComponent.initialized) {
          return resolve();
        }
        setTimeout(waitForInitialization, 50);
      }

      waitForInitialization();
    });
  }

  /**
   * This is a utility method for access to an element within the root element.
   * @summary Get element within root by class name.
   * @param {String} name - the CSS class name to find
   * @returns {HTMLElement} first element in the root matching the class name
   */
  getElm(name) {
    return this.rootElm.querySelector(`.${name}`);
  }

  /**
   * This is a utility method for access to elements within the root element.
   *
   * It is intended for cases where we expect there may be multiple elements of
   * the same class.
   * @summary Get all elements within root for a given class name.
   * @param {String} name - the CSS class name to find
   * @returns {Array} all elements in the root matching the class name
   */
  getElms(name) {
    return [...this.rootElm.querySelectorAll(`.${name}`)];
  }

  /**
   * Displays or hides an element.
   *
   * If hidden, the element will not occupy screen space. This method is
   * intended for an element that is displayed or hidden when the component is
   * initialized and then remains in that state for the lifetime of the
   * component.
   *
   * @param {string} selector The class name by which to select the element.
   * @param {boolean} displayed Whether to diplay the element
   *     (true = display the element).
   */
  setDisplayed(selector, displayed) {
    const method = displayed ? 'remove' : 'add';
    this.getElm(selector).classList[method]('u-hidden');
  }

  /**
   * Makes an element visible or invisible.
   *
   * If invisible, the element will still occupy screen space. This method is
   * meant to prevent visually jarring changes to the width and/or height of the
   * component if the element is to be toggled between visible and invisible
   * over the lifetime of the component.
   *
   * @param {string} selector The class name by which to select the element.
   * @param {boolean} displayed Whether to diplay the element
   *     (true = display the element).
   */
  setVisible(selector, visible) {
    const method = visible ? 'remove' : 'add';
    this.getElm(selector).classList[method]('u-invisible');
  }
}

export default FormComponent;
