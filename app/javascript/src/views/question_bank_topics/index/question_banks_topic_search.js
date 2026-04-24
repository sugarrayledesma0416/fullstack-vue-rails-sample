const QuestionBanksTopicSearch = class {

  /**
   *  Get the necessary elements to determine which elements
   *  will be displayed and which will not.
   */
  constructor() {
    this.input = document.querySelector('.js-search-input');
    this.allTopicElms = Array.from(document.querySelectorAll('.js-topic'));
    this.languageSelected = document.querySelector('.js-search-by-language');
    this.levelSelected = document.querySelector('.js-search-by-level');
    this.filterButton = document.querySelector('.js-filter-button');
    this.clearButton = document.querySelector('.js-clear-button');
    const storedLanguage = localStorage.getItem('languageSelected');
    const storedLevel = localStorage.getItem('levelSelected');

    if (storedLanguage) this.languageSelected.value = storedLanguage;
    if (storedLevel) this.levelSelected.value = storedLevel;
    if (!this.languageSelected.value) this.languageSelected.value = 'select';
    if (!this.levelSelected.value) this.levelSelected.value = 'select';

    this.filterTopics();
  }

  /**
   * It will capture the events and changes in the search bar
   * to filter the question banks elements
   */
  bindSearchEvent () {
    this.bindFilterTopicsChange();
    this.clearFilterTopics();

    this.input.addEventListener(
      'keyup',
      (event) => {
        const searchString = event.target.value.toLowerCase();
        this.allTopicElms.forEach(
          (elm) => {
            if (searchString === '' || elm.innerText.toLowerCase().indexOf(searchString) >= 0) {
              // if they clear the search field, show everything, otherwise,
              // show elements that match the search
              elm.classList.remove('u-hidden');
            } else {
              elm.classList.add('u-hidden');
            }
          }
        );
      }
    );
  }

  /**
   * Filter the question banks elements taking into account
   * the values that exist in the language and level dropdowns
   */
  bindFilterTopicsChange() {
    this.filterButton.addEventListener(
      'click',
      (event) => {
        this.filterTopics();
      }
    );
  }

  /**
   * Reset the filter to its default values
   */
  clearFilterTopics() {
    this.clearButton.addEventListener(
      'click',
      (event) => {
        this.languageSelected.value = 'select';
        this.levelSelected.value = 'select';
        localStorage.removeItem('languageSelected');
        localStorage.removeItem('levelSelected');
        this.allTopicElms.forEach(
          (elm) => {
            elm.classList.remove('u-hidden');
          });
      }
    );
  }

  /**
   * Determine which question bank topics will be displayed and which will not
   * @param {boolean} isVisibility - params to define question bank topics will be displayed.
   * @param {Object} elm - question bank topic element
   */
  toggleVisibility(isVisibility, elm) {
    if (isVisibility) {
      elm.classList.remove('u-hidden');
    } else {
      elm.classList.add('u-hidden');
    }
  }

  /**
   * Determine which question bank topic elements will be filtered
   */
  filterTopics() {
    if (this.languageSelected.value !== '' && this.languageSelected.value !== 'select') {
      localStorage.setItem('languageSelected', this.languageSelected.value);
    }
    if (this.levelSelected.value !== '' && this.levelSelected.value !== 'select') {
      localStorage.setItem('levelSelected', this.levelSelected.value);
    }

    this.allTopicElms.forEach(
      (elm) => {
        elm.classList.remove('u-hidden');
      });

    this.allTopicElms.forEach(
      (elm) => {
        if (this.languageSelected.value !== 'select' &&
          this.levelSelected.value === 'select') {
          this.toggleVisibility(this.filterLanguage(elm), elm);
        }

        if (this.levelSelected.value !== 'select' &&
          this.languageSelected.value === 'select') {
          this.toggleVisibility(this.filterLevel(elm), elm);
        }

        if (this.levelSelected.value !== 'select' &&
          this.languageSelected.value !== 'select') {
          this.toggleVisibility(this.filterLanguageAndLevel(elm), elm);
        }
      }
    );
  }

  /**
   * Get the set of question bank topics by language that will be visible
   * @param {Object} elm - question bank topic element
   * @return {boolean} - Determine the topic question banks
   * that meet the condition of the respective dropdow
   */
  filterLanguage(elm) {
    return this.languageSelected.value === elm.dataset.language.toLowerCase();
  }

  /**
   * Get the set of question banks topic by level that will be visible
   * @param {Object} elm - question bank topic element
   * @return {boolean} - Determine the topic question banks
   * that meet the condition of the respective dropdow
   */
  filterLevel(elm) {
    return this.levelSelected.value === elm.dataset.level.toLowerCase();
  }

  /**
   * Get the set of question banks topic by language and by level
   * that will be visible
   * @param {Object} elm - question bank topic element
   * @return {boolean} - Determine the topic question banks
   * that meet the condition of the respective dropdow
   */
  filterLanguageAndLevel(elm) {
    return this.languageSelected.value === elm.dataset.language.toLowerCase() &&
      this.levelSelected.value === elm.dataset.level.toLowerCase();
  }
};
export default QuestionBanksTopicSearch;
