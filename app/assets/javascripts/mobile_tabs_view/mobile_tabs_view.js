/**
 * Mobile Tabs View component
 * Class to handle UI states for mobile screen view with tabs
 */

VHL = VHL || {};

VHL.MobileTabsViewCls = class MobileTabsView {

  constructor(tabsConfig) {
    this._initConsts();
    this._init(tabsConfig);
  }

  /**
   * This function initializes constants/enums/maps etc to be used in code
   */
  _initConsts() {
    this.pageStateToCss = {
      INACTIVE: "c-mobile-tabs-view--inactive", 
      TABSET_HIDDEN: "c-mobile-tabs-view--active-with-tabset-hidden", 
      TABSET_VISIBLE: "c-mobile-tabs-view--active-with-tabset-visible",
    };
    
    this.rootJsClass = 'js-mobile-tabs-view';
    this.rootClass = 'c-mobile-tabs-view';
    this.tabContainerJsClass = 'js-mobile-tabset-container';
    this.tabContainerClass = 'c-mobile-tabset-container';

    this.tabsToCss = {
      PRIMARY: "c-mobile-tabs-view--show-primary-content", 
      REFERENCE: "c-mobile-tabs-view--show-reference-content", 
      OTHER: "c-mobile-tabs-view--show-other-content",
    };

    this.pageStateClasses = [
      "c-mobile-tabs-view--inactive",
      "c-mobile-tabs-view--active-with-tabset-hidden", 
      "c-mobile-tabs-view--active-with-tabset-visible"];

    this.tabClasses = [
      "c-mobile-tabs-view--show-primary-content", 
      "c-mobile-tabs-view--show-reference-content", 
      "c-mobile-tabs-view--show-other-content"];

    this.tabKeys = [
      "PRIMARY", 
      "REFERENCE", 
      "OTHER"];
  }

  /**
   * This function renders UI elements (tab buttons etc) and binds events 
   * @param  {Object} tabsConfig | Configuration json which tells about tab names etc.
   */
  _init(tabsConfig) {
    this._setupContainer();
    this._setupTabsUI(tabsConfig);
    this._bindEvents();

    // Set default state
    this.setState('INACTIVE');

    // Activate first tab as default
    this._tabClickHandler($('.js-mobile-tab-button').first());
  }
  
  /**
   * This function renders page UI as per the given page state
   * @param  {String} stateEnum | Valid page state as per specs
   */
  setState(stateEnum) {
    let newClass = this.pageStateToCss[stateEnum];
    this._setMobileViewClass(this.pageStateClasses, newClass);
  }

  /**
   * This function renders page UI such that it shows the page content linked 
   * to the given tab and hides other content as per the rules in the specs
   * @param  {String} tabEnum | Valid tab key name as per specs
   */
  setActiveTab(tabEnum) {
    let newClass = this.tabsToCss[tabEnum];
    this._setMobileViewClass(this.tabClasses, newClass);
  }

  /**
   * This function applies relevant css classes on the <body> element
   */
  _setupContainer() {
    let $bodyEle = $('body');
    $bodyEle.addClass(`${this.rootJsClass} 
                       ${this.rootClass}`);
  }

  /**
   * This function renders tab buttons from the handle bar template
   * @param  {Object} tabsConfig | Configuration json which tells about tab names etc.
   */
  _setupTabsUI(tabsConfig) {
    let templateEle = document.querySelector('.js-mobile-tabs-template');
    let tabContainer = document.querySelector(`.${this.tabContainerJsClass}`);
    if (tabContainer && templateEle) {
      let templateFunction = Handlebars.compile(templateEle.innerHTML);
      tabContainer.innerHTML = templateFunction(tabsConfig);
      tabContainer.classList.add(this.tabContainerClass);
      tabContainer.classList.remove('u-hidden');
    }
  }

  /*
   * This function shows only given tab buttons and hides rest of tab buttons
   * @param  {Array} tabKeysToShow | Array of tab key names only those tab buttons would be shown
   */

  showSpecificTabs(tabKeysToShow) {
    $('.js-mobile-tab-button').addClass('u-hidden');
    tabKeysToShow.forEach(tabKey => {
      if (this.tabKeys.indexOf(tabKey) == -1) {
        return;
      }
      $(`.js-mobile-tab-button-${tabKey}`).removeClass('u-hidden');
    })
  }

  _bindEvents() {
    $('.js-mobile-tab-button').click(event => {
      this._tabClickHandler($(event.currentTarget));
    });
  }
  
  /**
   * Handle click event on selected tab button
   * @param {Jquery Object} $tabButton - Clicked Tab button 
   */
  _tabClickHandler($tabButton) {
    if ($tabButton.length) {
      let tabKey = $tabButton.data('tab-key');
      $('.js-mobile-tab-button').removeClass('is-selected-tab');
      $tabButton.addClass('is-selected-tab');
      this.setActiveTab(tabKey);
      
      /* Rerender activity height as content might have changed due to show/hide*/
      this._resetActivityHeight();
    }
  }

  /**
   * This function applies css class on the root element, and removes other alternative css classes
   * @param  {Array} allClasses | Array of all alternative classnames, which would be removed
   * @param  {String} newClass | css class to apply
   */
  _setMobileViewClass(allClasses, newClass) {
    if (allClasses.indexOf(newClass) == -1) {
      return;
    }

    let $rootContainer =  $(`.${this.rootJsClass}`);
    if ($rootContainer.length) {
      allClasses.forEach(item => {
        $rootContainer.removeClass(item);
      })

      $rootContainer.addClass(newClass);
    }
  }
  
  /**
   * This function uses ActivityShell's function to rerender activity height
   */
  _resetActivityHeight() {
    if (VHL && VHL.ActivityShell 
        && typeof VHL.ActivityShell.setActivityHeight == 'function') {
      VHL.ActivityShell.setActivityHeight();
    }
  }
}
