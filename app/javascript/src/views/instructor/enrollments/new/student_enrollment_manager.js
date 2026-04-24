/**
 * Manages student enrollment workflow.
 * @class StudentEnrollmentManager
 */
export class StudentEnrollmentManager {
  /**
   * Initializes DOM elements and event listeners.
   */
  constructor() {
    this.addStudentBtn = document.querySelector(StudentEnrollmentManager.selectors.addStudentBtn);
    this.confirmationDialog = document.querySelector(StudentEnrollmentManager.selectors.confirmationDialog);
    this.searchForm = document.querySelector(StudentEnrollmentManager.selectors.searchForm);
    this.boundEnableAddStudentButton = this.enableAddStudentButton.bind(this);
    
    this.init();
  }

  /**
   * Returns an object containing JS selectors
   * @returns {Object} Object with JS selectors for UI elements
   */
  static get selectors() {
    return {
      addStudentBtn: '.js-add-student-submit',
      confirmationDialog: '.js-add-students-confirm-dialog',
      searchForm: '#search_student',
      unenrolledStudents: '.js-unenrolled-students',
      searchResults: '.js-search-results',
      studentCheckbox: '.js-student-checkbox',
      searchInput: '.js-search-input',
      cancelDialog: '.js-cancel-dialog',
      confirmationMessage: '.js-confirmation-message',
      studentsList: '.js-students-list',
      enrollmentNotice: '.js-enrollment-notice',
      searchResultsNotice: '.js-search-results-notice',
      searchResultsAnnouncement: '.js-search-results-announcement',
      noResults: '.js-no-results',
      clearSearch: '.js-clear-search',
      tableEnrollments: '.js-table-enrollments'
    };
  }

  /**
   * Returns the current container element based on the current view state.
   * @returns {Element|null} The current container element (unenrolled students or search results)
   * @readonly
   */
  get container() {
    return this.state === 'unenrolled' ?
      document.querySelector(StudentEnrollmentManager.selectors.unenrolledStudents) : document.querySelector(StudentEnrollmentManager.selectors.searchResults);
  }

  /**
   * Returns all student checkboxes within the current container.
   * @returns {NodeList} NodeList of student checkbox elements
   * @readonly
   */
  get studentCheckboxes() {
    return this.container.querySelectorAll(StudentEnrollmentManager.selectors.studentCheckbox);
  }

  /**
   * Initializes views and event listeners.
   */
  init() {
    this.initUnenrolledView();
    this.bindSearchFormSubmit();
    this.bindClearSearchButton();
    this.bindAddStudentButton();
    this.bindCloseDialog();
  }

  /**
   * Initializes the unenrolled students view and binds checkbox events.
   */
  initUnenrolledView() {
    this.changeView('unenrolled');
    this.bindStudentCheckboxes();
  }

  /**
   * Binds click event to the add student button to show confirmation dialog.
   */
  bindAddStudentButton() {
    this.addStudentBtn.addEventListener('click', (event) => { 
      event.preventDefault();
      this.pluralizeConfirmationMessage();
      this.populateConfirmationStudentsList();
      this.addEnrollmentNotice();
    });
  }

  /**
   * Binds clear event to the search input field to return to unenrolled view.
   */
  bindClearSearchButton() {
    const searchField = this.searchForm?.querySelector(StudentEnrollmentManager.selectors.searchInput);
    if (!searchField) return;

    searchField.addEventListener('sl-clear', (event) => { 
      event.preventDefault();
      this.initUnenrolledView();
    });
  }

  /**
   * Binds click event to the dialog close button to hide the confirmation dialog.
   */
  bindCloseDialog() {
    const close = this.confirmationDialog?.querySelector(StudentEnrollmentManager.selectors.cancelDialog);
    if (!close) return;
    
    close.addEventListener('click', (event) => { 
      event.preventDefault();
      this.confirmationDialog.hide();
    });
  }

  /**
   * Updates the confirmation message to use singular or plural form based on selected students.
   */
  pluralizeConfirmationMessage() {
    const messageContainer = this.confirmationDialog?.querySelector(StudentEnrollmentManager.selectors.confirmationMessage);
    if (!messageContainer) return;
    
    messageContainer.textContent =
      [...this.studentCheckboxes].filter(cb => cb.checked).length === 1 ? 'student' : 'students';
  }

  /**
   * Binds change events to student checkboxes and enables the add student button.
   */
  bindStudentCheckboxes() {
    this.enableAddStudentButton();
    this.container.addEventListener('sl-change', this.boundEnableAddStudentButton);
  }

  /**
   * Enables or disables the Add Student button based on checkbox selection state.
   */
  enableAddStudentButton() {
    this.addStudentBtn.disabled = ![...this.studentCheckboxes].some(cb => cb.checked);
  }

  /**
   * Removes event listeners from student checkboxes.
   */
  removeCheckboxesEvents() {
    this.container.removeEventListener('sl-change', this.boundEnableAddStudentButton);
  }

  /** Populates a <ul> element with <li> elements containing the selected students' names */
  populateConfirmationStudentsList() {
    const selectStudentContainer = this.confirmationDialog?.querySelector(StudentEnrollmentManager.selectors.studentsList);
    if (!selectStudentContainer) return;

    selectStudentContainer.innerHTML = '';
    
    [...this.studentCheckboxes].filter(cb => cb.checked).forEach(cb => {
      const li = document.createElement('li');
      li.textContent = cb.textContent.trim();
      selectStudentContainer.appendChild(li);
    })
    this.confirmationDialog.show();
  }
  
  /**
   * Binds submit event to the search form.
   */
  bindSearchFormSubmit() {
    if (!this.searchForm) return;

    this.searchForm.addEventListener('submit', (event) => {
      event.preventDefault();
      this.searchRequest();
    });
  }

  /**
   * Search request to get students.
   */
  async searchRequest() {
    try {
      const formData = new FormData(this.searchForm);
      const params = new URLSearchParams(formData);
      const url = `${this.searchForm.action}?${params.toString()}`;

      let fetchOptions = {
        method: 'GET',
        headers: {
          'X-Requested-With': 'XMLHttpRequest'
        }
      };

      const response = await fetch(url, fetchOptions);
      
      if (!response.ok) {
        throw new Error(`Search error: ${response.status} ${response.statusText}`);
      }
      
      const html = await response.text();
      this.handleSearchResponse(html);
    } catch (error) {
      console.error('Error searching for students:', error);
      this.handleSearchError();
    }
  }

  /**
   * Handles the response from the search request and updates the view.
   * @param {string} html - The HTML response from the search request
   */
  handleSearchResponse(html) {
    this.changeView('search');
    this.initSearchView(html);
  }

  /**
   * Handles search errors and displays appropriate error message to the user.
   */
  handleSearchError() {
    this.changeView('search');
    
    // Create error HTML
    const errorHtml = `
      <div class="u-mar-top-24  js-no-results" 
       role="status" 
       aria-live="polite"
       data-error="true">
      </div>
      <l-stack-v3 gap="6" align-y="center" align-x="center">
        <h2 class="c-heading-v3--2  u-mar-top-64">Server error</h2>
        <sl-button
          type="submit"
          class="sl-button-v3  sl-button-v3--primary-clear  js-clear-search">
          Clear Search
        </sl-button>
      </l-stack-v3>
    `;
    
    this.container.innerHTML = errorHtml;
    this.bindNoResultsBtn();
    this.announceSearchResults();
  }

  /**
   * Changes the current view between unenrolled and search results.
   * @param {string} newView - The new view state 'unenrolled|'search'
   * @private
   */
  changeView(newView) {
    this.removeCheckboxesEvents();
    this.container.classList.add('u-hidden');
    this.state = newView;
    this.container.classList.remove('u-hidden');

  }

  /**
   * Initializes the search results view.
   * @param {string} html - The HTML content to display in the search results container
   */
  initSearchView(html) {
    this.container.innerHTML = html;
    this.bindStudentCheckboxes();
    this.announceSearchResults();
    this.bindNoResultsBtn();
    document.querySelector(StudentEnrollmentManager.selectors.tableEnrollments)?.focus();
  }

  /**
   * Adds enrollment notice to the confirmation dialog if in search view.
   */
  addEnrollmentNotice() {
    const noticeContainer = this.confirmationDialog?.querySelector(StudentEnrollmentManager.selectors.enrollmentNotice);
    const enrollmentMessage = this.container?.querySelector(StudentEnrollmentManager.selectors.searchResultsNotice);
    const hasActiveSections = [...this.studentCheckboxes].some(cb => cb.checked && cb.dataset.activeSections === 'true');
    
    noticeContainer.innerHTML = '';
    noticeContainer.classList.add('u-hidden');

    if (this.state === 'search' && enrollmentMessage && hasActiveSections) {
      noticeContainer.innerHTML = enrollmentMessage.innerHTML.trim();
      noticeContainer.classList.remove('u-hidden');
    }
  }

  /**
   * Announces search results to screen readers.
   */
  announceSearchResults() {
    const announcementElement = document.querySelector(StudentEnrollmentManager.selectors.searchResultsAnnouncement);
    const noResultsElement = this.container?.querySelector(StudentEnrollmentManager.selectors.noResults);
    
    let announcementText = '';
    
    if (noResultsElement?.dataset.error) {
      announcementText = 'Server error.';
    } else if (noResultsElement) {
      announcementText = 'No results found.';
    } else {
      announcementText = 'Search completed.';
    }

     /** Waits to make sure the announcementElement is removed before announcing it again */
    if (announcementElement) {
      announcementElement.textContent = '';
      
      setTimeout(() => {
        announcementElement.textContent = announcementText;
      }, 100);
    }
  }

  /**
   * Binds click event to the "no results" clear search button.
   * @private
   */
  bindNoResultsBtn() {
    const clearSearch = document.querySelector(StudentEnrollmentManager.selectors.clearSearch);
    if (!clearSearch) return;

    clearSearch.addEventListener('click', (event) => { 
      event.preventDefault();
      this.initUnenrolledView();
    });
  }
}
