import { mount } from '@vue/test-utils';
import * as ajaxUtils from 'shared/ajax_utils';
import fetchMock from 'fetch-mock';

import StateEditingModal from 'features/individual_assignments/StateEditingModal';
import Datastore from 'features/individual_assignments/models/datastore';

describe(
  'StateEditingModal',
  () => {
    let entry;
    let store;
    let wrapper;

    const programId = '45678';
    const props = { programId };

    function getWrapper() {
      return mount(
        StateEditingModal,
        { global: { provide: { store }}, props }
      );
    }

    beforeEach(
      () => {
        entry = {
          assignable_id: 111,
          individually_assignable: true,
        };

        store = new Datastore({ 123: [entry] });
      }
    );

    it(
      'does not display a modal if no activityId is being edited',
      () => {
        wrapper = getWrapper();
        expect(
          wrapper.findComponent({ name: 'ModalComponent' }).exists()
        ).toBeFalsy();
      }
    );

    describe(
      'when an activityId is being edited',
      () => {
        beforeEach(
          () => {
            store.startEditing(entry.assignable_id);
          }
        );

        it(
          'displays a modal',
          () => {
            wrapper = getWrapper();

            expect(
              wrapper.findComponent({ name: 'ModalComponent' }).exists()
            ).toBeTruthy();
          }
        );

        it(
          'marks the "false" option in the assignable dropdown menu as ' +
          'selected if the entry is not individually-assignable',
          () => {
            entry.individually_assignable = false;
            wrapper = getWrapper();

            expect(
              wrapper.findAll('option').map(
                (option) => option.element.selected
              )
            ).toEqual([true, false]);
          }
        );

        it(
          'marks the "true" option in the assignable dropdown menu as ' +
          'selected if the entry is individually-assignable',
          () => {
            entry.individually_assignable = true;
            wrapper = getWrapper();

            expect(
              wrapper.findAll('option').map(
                (option) => option.element.selected
              )
            ).toEqual([false, true]);
          }
        );

        it(
          'clears the activityId currently being edited when the cancel ' +
          'button is clicked',
          async () => {
            wrapper = getWrapper();

            const cancelButton = wrapper.get('.test-cancel-state-editing');

            await cancelButton.trigger('click');

            expect(store.state.activityIdBeingEdited).toBeNull();
          }
        );

        describe(
          'when the save button is clicked',
          () => {
            const endpointUrl = '/instructor/45678/individual_assignments/111';

            beforeEach(
              () => {
                spyOn(store, 'updateAssignableState');

                spyOn(ajaxUtils, 'putToEndpoint').and.callThrough();
                fetchMock.mock(endpointUrl, { status: 200 });

                wrapper = getWrapper();
              }
            );

            afterEach(() => fetchMock.restore());

            describe(
              'when the "true" value is selected from the dropdown"',
              () => {
                beforeEach(
                  async () => {
                    const dropdown = wrapper.get('select');
                    dropdown.element.value = 'true';
                    await dropdown.trigger('change');

                    const saveButton = wrapper.get('.test-save-state-changes');
                    await saveButton.trigger('click');
                  }
                );

                it(
                  'does an ajax put request setting the ' +
                  'individually-assignable state to true',
                  () => {
                    expect(ajaxUtils.putToEndpoint).toHaveBeenCalledWith(
                      endpointUrl,
                      { individually_assignable: true },
                      jasmine.any(Function)
                    );
                  }
                );

                it(
                  'calls updateAssignableState on the datastore, specifying ' +
                  'the activityId and a true individually-assignable state',
                  async () => {
                    await fetchMock.flush(true);

                    expect(store.updateAssignableState).toHaveBeenCalledWith(
                      entry.assignable_id, true
                    );
                  }
                );
              }
            );

            describe(
              'when the "false" value is selected from the dropdown"',
              () => {
                beforeEach(
                  async () => {
                    const dropdown = wrapper.get('select');
                    dropdown.element.value = 'false';
                    await dropdown.trigger('change');

                    const saveButton = wrapper.get('.test-save-state-changes');
                    await saveButton.trigger('click');
                  }
                );

                it(
                  'does an ajax put request setting the ' +
                  'individually-assignable state to false',
                  () => {
                    expect(ajaxUtils.putToEndpoint).toHaveBeenCalledWith(
                      endpointUrl,
                      { individually_assignable: false },
                      jasmine.any(Function)
                    );
                  }
                );

                it(
                  'calls updateAssignableState on the datastore, specifying ' +
                  'the activityId and a false individually-assignable state',
                  async () => {
                    await fetchMock.flush(true);

                    expect(store.updateAssignableState).toHaveBeenCalledWith(
                      entry.assignable_id, false
                    );
                  }
                );
              }
            );
          }
        );
      }
    );
  }
);
