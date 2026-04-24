import { reactive } from 'vue';
import { mount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { setActivePinia } from 'pinia';
import useIndividualAssignmentsStore
  from 'features/individual_assignments/stores/use_individual_assignments_store';

import StudentCell from 'features/individual_assignments/StudentCell';
import Datastore from 'features/individual_assignments/models/datastore';

describe('StudentCell', () => {
  let assignment;
  let wrapper;

  const userIdWithPrefix = 'user_123';
  const datastore = new Datastore({});
  const testSelector = 'due-date-display';

  beforeEach(() => {
    setActivePinia(createTestingPinia());
    const store = useIndividualAssignmentsStore();
    store.init({
      maxDueDate: '9/26/2022',
      minDueDate: '9/21/2022',
    });

    assignment = reactive(
      {
        assignable_id: 456,
        individually_assignable: true,
        individually_assigned: true,
      }
    );
    wrapper = getWrapper(assignment);
  });

  function getWrapper(assignment) {
    return mount(
      StudentCell,
      {
        global: {
          provide: { store: datastore },
          stubs: {
            LazyRender: {
              template: '<div><slot /></div>',
            },
          },
        },
        props: { assignment, testSelector, userIdWithPrefix },
      }
    );
  }

  function getCell() {
    return wrapper.get('td');
  }

  function getCheckbox() {
    return wrapper.get('input[type="checkbox"]');
  }

  it('renders a checkbox with a name based on the userId prop and ' +
     'the activity id of the assignment', () => {
    expect(getCheckbox().attributes('name')).toBe('activity_456[user_123][assigned]');
  });

  describe('when the assignment is not individually-assignable', () => {
    beforeEach(() => assignment.individually_assignable = false);

    it('sets a "disabled" class on the cell', () => {
      expect(getCell().classes()).toContain('individual-assignments-disabled-cell');
    });

    it('does not render a hidden field', () => {
      expect(wrapper.find('input[type="hidden"]').exists()).toBeFalsy();
    });

    describe('when the user clicks inside the table cell', () => {
      it('does not toggle the checked state of the checkbox', async () => {
        const tableCell = getCell();
        await tableCell.trigger('click');

        /**
         * The checkbox is hard-coded as checked and should remain checked
         * after the click.
         */
        expect(getCheckbox().element.checked).toBeTruthy();
      });
    });

    describe('when the user clicks the checkbox', () => {
      beforeEach(async () => {
        const checkbox = getCheckbox();
        await checkbox.trigger('click');
      });

      it('does not toggle the checked state of the checkbox', () => {
        expect(getCheckbox().element.checked).toBeTruthy();
      });

      it('does not emit a toggleCheckbox event', () => {
        expect(wrapper.emitted().toggleCheckbox).toBe(undefined);
      });
    });
  });

  describe('when the assignment is individually-assignable', () => {
    beforeEach(() => assignment.individually_assignable = true);

    describe('when the assignment is assigned to the current student', () => {
      beforeEach(() => assignment.individually_assigned = true);

      it('sets an "assigned" class on the cell', () => {
        expect(getCell().classes()).toContain('individual-assignments-assigned-cell');
      });

      it('renders the checkbox as checked',
        () => expect(getCheckbox().element.checked).toBeTruthy()
      );
    });

    describe('when the assignment is not assigned to the current student', () => {
      beforeEach(() => assignment.individually_assigned = false);

      it('sets an "unassigned" class on the cell', () => {
        expect(getCell().classes()).toContain('individual-assignments-unassigned-cell');
      });

      it('renders the checkbox as unchecked',
        () => expect(getCheckbox().element.checked).toBeFalsy()
      );
    });

    it('renders a hidden field', () => {
      expect(wrapper.find('input[type="hidden"]').exists()).toBeTruthy();
    });

    it('sets the name of the hidden field based on the userId prop and ' +
       'the activity id of the assignment', () => {
      const hiddenField = wrapper.get('input[type="hidden"]');

      expect(hiddenField.attributes('name')).toBe('activity_456[user_123][assigned]');
    });

    it('sets the checkbox input to not be disabled', () => {
      expect(getCheckbox().element.disabled).toBeFalsy();
    });
  });

  describe('when the user clicks inside the table cell', () => {
    it('toggles the checked state of the checkbox', async () => {
      const tableCell = getCell();
      await tableCell.trigger('click');

      expect(getCheckbox().element.checked).toBeFalsy();
    });
  });

  describe('when the user clicks the checkbox', () => {
    beforeEach(async () => {
      const checkbox = getCheckbox();
      await checkbox.trigger('click');
      await checkbox.trigger('change');
    });

    it('toggles the checked state of the checkbox', () => {
      expect(getCheckbox().element.checked).toBeFalsy();
    });

    it('emits a toggleCheckbox event', () => {
      expect(wrapper.emitted().toggleCheckbox).toHaveLength(1);
    });
  });

  describe('individual due date field', () => {
    beforeEach(() => {
      assignment = reactive({
        assignable_id: 456,
        individually_assignable: true,
        individually_assigned: true,
      });
      wrapper = getWrapper(assignment);
    });

    describe('when cell is individually assigned ' +
             'and show_due_date_field is set to true on the entry', () => {
      describe('when the cell has an individual due date', () => {
        it('sets that due date as the date to submit', () => {
          assignment = reactive({
            assignable_id: 456,
            due_date: '9/25/2022',
            individual_due_date: '9/24/2022',
            individually_assignable: true,
            individually_assigned: true,
            show_due_date_field: true,
          });

          const dueDateHiddenField = getWrapper(assignment).find('.test-due-date-hidden-field');

          expect(dueDateHiddenField.attributes('value')).toEqual('9/24/2022');
        });
      });
    });
  });
});
