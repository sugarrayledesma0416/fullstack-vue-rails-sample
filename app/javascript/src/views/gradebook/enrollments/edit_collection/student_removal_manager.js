/**
 * StudentRemovalManager handles the UI logic for removing students from a roster.
 * This class is designed to be easily testable by allowing dependency injection
 * and separating business logic from DOM manipulation.
 */
class StudentRemovalManager {
  constructor(options = {}) {
    this.document = options.document || document;
    this.selectors = {
      checkboxes: '.js-drop-form .js-checkbox',
      openConfirmButton: '.js-open-confirm',
      confirmOverlay: '.js-confirm-drop-overlay',
      dropForm: '.js-drop-form',
      confirmDropButton: '.js-confirm-drop',
      cancelDropButton: '.js-cancel-drop',
      studentList: '.js-student-list'
    };
  }

  /**
   * Initialize the student removal functionality by binding event handlers.
   */
  init() {
    this.bindEventHandlers();
  }

  /**
   * Bind all event handlers to their respective DOM elements.
   */
  bindEventHandlers() {
    this.bindCheckboxHandlers();
    this.bindOpenConfirmHandler();
    this.bindFormSubmitHandler();
    this.bindCancelHandler();
  }

  /**
   * Bind click handlers to student checkboxes.
   */
  bindCheckboxHandlers() {
    const checkboxes = this.document.querySelectorAll(this.selectors.checkboxes);
    checkboxes.forEach((checkbox) => {
      checkbox.addEventListener('click', (event) => {
        this.handleStudentSelection(event);
        this.handleRemoveButtonDisabled();
      }); 
    });
  }

  /**
   * Bind click handler to open confirmation dialog button.
   */
  bindOpenConfirmHandler() {
    const openConfirmButton = this.document.querySelector(this.selectors.openConfirmButton);
    if (openConfirmButton) {
      openConfirmButton.addEventListener('click', () => {
        this.openConfirmationDialog();
      });
    }
  }

  /**
   * Bind submit handler to the drop form.
   */
  bindFormSubmitHandler() {
    const dropForm = this.document.querySelector(this.selectors.dropForm);
    if (dropForm) {
      dropForm.addEventListener('submit', (event) => {
        this.handleFormSubmit(event);
      });
    }
  }

  /**
   * Bind click handler to cancel button.
   */
  bindCancelHandler() {
    const cancelButton = this.document.querySelector(this.selectors.cancelDropButton);
    if (cancelButton) {
      cancelButton.addEventListener('click', (event) => {
        this.handleCancel(event);
      });
    }
  }

  /**
   * Open the confirmation dialog.
   */
  openConfirmationDialog() {
    const overlay = this.document.querySelector(this.selectors.confirmOverlay);
    if (overlay && overlay.show) {
      overlay.show();
    }
  }

  /**
   * Handle form submission by adding loading state to the confirm button.
   * @param {Event} event - The submit event
   */
  handleFormSubmit(event) {
    const button = event.target.querySelector(this.selectors.confirmDropButton);
    if (button) {
      this.addLoadingState(button);
    }
  }

  /**
   * Add loading state to a button.
   * @param {HTMLElement} button - The button element
   */
  addLoadingState(button) {
    const spinner = this.document.createElement('sl-spinner');
    spinner.setAttribute('style', '--indicator-color: var(--music-red-500)');
    button.appendChild(spinner);
    button.style.pointerEvents = 'none';
    button.disabled = true;
  }

  /**
   * Handle cancel button click.
   * @param {Event} event - The click event
   */
  handleCancel(event) {
    event.preventDefault();
    this.hideConfirmationDialog();
  }

  /**
   * Hide the confirmation dialog.
   */
  hideConfirmationDialog() {
    const overlay = this.document.querySelector(this.selectors.confirmOverlay);
    if (overlay && overlay.hide) {
      overlay.hide();
    }
  }

  /**
   * Handle student selection checkbox click.
   * Updates the dialog list of selected students.
   * @param {Event} event - The click event
   */
  handleStudentSelection(event) {
    const isChecked = event.target.checked;
    const student = event.target.dataset.studentName;
    
    if (!student) return;

    const studentId = this.getStudentId(student);
    const studentListItem = this.document.getElementById(studentId);
    const list = this.document.querySelector(this.selectors.studentList);

    if (studentListItem && !isChecked) {
      this.removeStudentFromList(list, studentListItem);
    } else if (!studentListItem && isChecked) {
      this.addStudentToList(list, student, studentId);
    }
  }

  /**
   * Get the student ID for DOM element identification.
   * @param {string} studentName - The student's name
   * @returns {string} The student ID
   */
  getStudentId(studentName) {
    return `student-${studentName.replace(/\s+/g, '-')}`;
  }

  /**
   * Remove a student from the list.
   * @param {HTMLElement} list - The list element
   * @param {HTMLElement} studentListItem - The student list item to remove
   */
  removeStudentFromList(list, studentListItem) {
    if (list && studentListItem) {
      list.removeChild(studentListItem);
    }
  }

  /**
   * Add a student to the list.
   * @param {HTMLElement} list - The list element
   * @param {string} studentName - The student's name
   * @param {string} studentId - The student's ID
   */
  addStudentToList(list, studentName, studentId) {
    if (list) {
      const listItem = this.document.createElement('li');
      listItem.setAttribute('id', studentId);
      listItem.textContent = studentName;
      list.appendChild(listItem);
    }
  }

  /**
   * Handle enabling/disabling the remove button based on selection state.
   */
  handleRemoveButtonDisabled() {
    const hasSelectedStudents = this.hasSelectedStudents();
    const openConfirmButton = this.document.querySelector(this.selectors.openConfirmButton);
    
    if (openConfirmButton) {
      this.setDisabled(openConfirmButton, hasSelectedStudents);
    }
  }

  /**
   * Check if any students are selected.
   * @returns {boolean} True if any students are selected
   */
  hasSelectedStudents() {
    const checkboxes = this.document.querySelectorAll(this.selectors.checkboxes);
    const checkboxesArray = Array.from(checkboxes);
    return checkboxesArray.some(item => item.checked);
  }

  /**
   * Enable or disable a given element.
   * @param {HTMLElement} element - The element to enable/disable
   * @param {boolean} isEnabled - True to enable, false to disable
   */
  setDisabled(element, isEnabled) {
    if (!element) return;

    if (isEnabled) {
      element.removeAttribute('disabled');
      element.style.pointerEvents = '';
    } else {
      element.setAttribute('disabled', true);
      element.style.pointerEvents = 'none';
    }
  }
}

export default StudentRemovalManager;

