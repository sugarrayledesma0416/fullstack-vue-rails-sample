import StudentRemovalManager from '~/src/views/gradebook/enrollments/edit_collection/student_removal_manager.js';

describe('StudentRemovalManager', () => {
  let manager;
  let mockDocument;
  let mockElements;

  beforeEach(() => {
    // Create mock DOM elements
    mockElements = {
      checkboxes: [
        { checked: false, dataset: { studentName: 'John Doe' }, addEventListener: vi.fn() },
        { checked: true, dataset: { studentName: 'Jane Smith' }, addEventListener: vi.fn() }
      ],
      openConfirmButton: { addEventListener: vi.fn(), removeAttribute: vi.fn(), setAttribute: vi.fn() },
      confirmOverlay: { show: vi.fn(), hide: vi.fn() },
      dropForm: { addEventListener: vi.fn() },
      cancelButton: { addEventListener: vi.fn() },
      studentList: { appendChild: vi.fn(), removeChild: vi.fn() }
    };

    // Create mock document
    mockDocument = {
      querySelectorAll: vi.fn((selector) => {
        if (selector === '.js-drop-form .js-checkbox') return mockElements.checkboxes;
        return [];
      }),
      querySelector: vi.fn((selector) => {
        const selectorMap = {
          '.js-open-confirm': mockElements.openConfirmButton,
          '.js-confirm-drop-overlay': mockElements.confirmOverlay,
          '.js-drop-form': mockElements.dropForm,
          '.js-cancel-drop': mockElements.cancelButton,
          '.js-student-list': mockElements.studentList
        };
        return selectorMap[selector] || null;
      }),
      getElementById: vi.fn((id) => {
        if (id === 'student-John-Doe') return null; // Not in list
        if (id === 'student-Jane-Smith') return { id: 'student-Jane-Smith' }; // In list
        return null;
      }),
      createElement: vi.fn((tagName) => {
        if (tagName === 'sl-spinner') return { tagName: 'sl-spinner' };
        return { setAttribute: vi.fn(), textContent: '' };
      })
    };

    // Create manager instance with mock document
    manager = new StudentRemovalManager({ document: mockDocument });
  });

  describe('constructor', () => {
    it('should initialize with default document if none provided', () => {
      const defaultManager = new StudentRemovalManager();
      expect(defaultManager.document).toBe(document);
    });
  });

  describe('init', () => {
    it('should call bindEventHandlers', () => {
      const bindEventHandlersSpy = vi.spyOn(manager, 'bindEventHandlers');
      manager.init();
      expect(bindEventHandlersSpy).toHaveBeenCalled();
    });
  });

  describe('bindEventHandlers', () => {
    it('should bind all event handlers', () => {
      const bindCheckboxHandlersSpy = vi.spyOn(manager, 'bindCheckboxHandlers');
      const bindOpenConfirmHandlerSpy = vi.spyOn(manager, 'bindOpenConfirmHandler');
      const bindFormSubmitHandlerSpy = vi.spyOn(manager, 'bindFormSubmitHandler');
      const bindCancelHandlerSpy = vi.spyOn(manager, 'bindCancelHandler');

      manager.bindEventHandlers();

      expect(bindCheckboxHandlersSpy).toHaveBeenCalled();
      expect(bindOpenConfirmHandlerSpy).toHaveBeenCalled();
      expect(bindFormSubmitHandlerSpy).toHaveBeenCalled();
      expect(bindCancelHandlerSpy).toHaveBeenCalled();
    });
  });

  describe('handleStudentSelection', () => {
    it('should add student to list when checked and not already in list', () => {
      const event = {
        target: {
          checked: true,
          dataset: { studentName: 'John Doe' }
        }
      };

      manager.handleStudentSelection(event);

      expect(mockDocument.getElementById).toHaveBeenCalledWith('student-John-Doe');
      expect(mockDocument.querySelector).toHaveBeenCalledWith('.js-student-list');
    });

    it('should remove student from list when unchecked and in list', () => {
      const event = {
        target: {
          checked: false,
          dataset: { studentName: 'Jane Smith' }
        }
      };

      manager.handleStudentSelection(event);

      expect(mockDocument.getElementById).toHaveBeenCalledWith('student-Jane-Smith');
    });

  });

  describe('hasSelectedStudents', () => {
    it('should return true when some students are selected', () => {
      expect(manager.hasSelectedStudents()).toBe(true);
    });

    it('should return false when no students are selected', () => {
      mockElements.checkboxes.forEach(checkbox => checkbox.checked = false);
      expect(manager.hasSelectedStudents()).toBe(false);
    });
  });

  describe('setDisabled', () => {
    it('should enable element when isEnabled is true', () => {
      const element = { removeAttribute: vi.fn(), style: {} };
      manager.setDisabled(element, true);

      expect(element.removeAttribute).toHaveBeenCalledWith('disabled');
      expect(element.style.pointerEvents).toBe('');
    });

    it('should disable element when isEnabled is false', () => {
      const element = { setAttribute: vi.fn(), style: {} };
      manager.setDisabled(element, false);

      expect(element.setAttribute).toHaveBeenCalledWith('disabled', true);
      expect(element.style.pointerEvents).toBe('none');
    });

    it('should return early if element is null', () => {
      expect(() => manager.setDisabled(null, true)).not.toThrow();
    });
  });

  describe('openConfirmationDialog', () => {
    it('should call show on overlay if it exists', () => {
      manager.openConfirmationDialog();
      expect(mockElements.confirmOverlay.show).toHaveBeenCalled();
    });
  });

  describe('hideConfirmationDialog', () => {
    it('should call hide on overlay if it exists', () => {
      manager.hideConfirmationDialog();
      expect(mockElements.confirmOverlay.hide).toHaveBeenCalled();
    });
  });

  describe('handleFormSubmit', () => {
    it('should call addLoadingState with confirm button', () => {
      const mockButton = { appendChild: vi.fn(), style: {} };
      const mockSpinner = { setAttribute: vi.fn() };
      const event = {
        target: {
          querySelector: vi.fn(() => mockButton)
        }
      };
      const addLoadingStateSpy = vi.spyOn(manager, 'addLoadingState');
      
      // Override the createElement mock for this test
      mockDocument.createElement.mockImplementation((tagName) => {
        if (tagName === 'sl-spinner') return mockSpinner;
        return { setAttribute: vi.fn(), textContent: '' };
      });

      manager.handleFormSubmit(event);

      expect(event.target.querySelector).toHaveBeenCalledWith('.js-confirm-drop');
      expect(addLoadingStateSpy).toHaveBeenCalledWith(mockButton);
    });
  });

  describe('addLoadingState', () => {
    it('should add spinner and disable button', () => {
      const mockButton = { appendChild: vi.fn(), style: {} };
      const mockSpinner = { setAttribute: vi.fn() };
      mockDocument.createElement.mockReturnValue(mockSpinner);

      manager.addLoadingState(mockButton);

      expect(mockDocument.createElement).toHaveBeenCalledWith('sl-spinner');
      expect(mockSpinner.setAttribute).toHaveBeenCalledWith('style', '--indicator-color: var(--music-red-500)');
      expect(mockButton.appendChild).toHaveBeenCalledWith(mockSpinner);
      expect(mockButton.style.pointerEvents).toBe('none');
      expect(mockButton.disabled).toBe(true);
    });
  });

  describe('handleCancel', () => {
    it('should prevent default and hide dialog', () => {
      const event = { preventDefault: vi.fn() };
      const hideDialogSpy = vi.spyOn(manager, 'hideConfirmationDialog');

      manager.handleCancel(event);

      expect(event.preventDefault).toHaveBeenCalled();
      expect(hideDialogSpy).toHaveBeenCalled();
    });
  });

  describe('addStudentToList', () => {
    it('should create and append list item', () => {
      const mockList = { appendChild: vi.fn() };
      const mockListItem = { setAttribute: vi.fn(), textContent: '' };
      mockDocument.createElement.mockReturnValue(mockListItem);

      manager.addStudentToList(mockList, 'John Doe', 'student-John-Doe');

      expect(mockDocument.createElement).toHaveBeenCalledWith('li');
      expect(mockListItem.setAttribute).toHaveBeenCalledWith('id', 'student-John-Doe');
      expect(mockListItem.textContent).toBe('John Doe');
      expect(mockList.appendChild).toHaveBeenCalledWith(mockListItem);
    });

    it('should not append if list is null', () => {
      manager.addStudentToList(null, 'John Doe', 'student-John-Doe');
      expect(mockDocument.createElement).not.toHaveBeenCalled();
    });
  });

  describe('removeStudentFromList', () => {
    it('should remove student from list', () => {
      const mockList = { removeChild: vi.fn() };
      const mockStudentItem = { id: 'student-John-Doe' };

      manager.removeStudentFromList(mockList, mockStudentItem);

      expect(mockList.removeChild).toHaveBeenCalledWith(mockStudentItem);
    });

    it('should not remove if list or student item is null', () => {
      const mockList = { removeChild: vi.fn() };

      manager.removeStudentFromList(null, {});
      manager.removeStudentFromList(mockList, null);

      expect(mockList.removeChild).not.toHaveBeenCalled();
    });
  });
});