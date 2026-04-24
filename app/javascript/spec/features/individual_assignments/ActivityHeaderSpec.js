import { mount } from '@vue/test-utils';

import ActivityHeader from 'features/individual_assignments/ActivityHeader';
import Datastore from 'features/individual_assignments/models/datastore';

describe('ActivityHeader', () => {
  let wrapper;
  let chunk;
  let entry;

  const datastore = new Datastore({});

  function getWrapper() {
    return mount(
      ActivityHeader,
      {
        global: { provide: { store: datastore }},
        props: { chunk, entry },
      }
    );
  }

  beforeEach(() => {
    entry = {
      activity_title: 'abc',
      assignable_id: 123,
      due_date: '9/25',
      individual_due_date: null,
      individually_assignable: true,
    };
  });

  describe('when the "chunk" prop is not set to "full"', () => {
    beforeEach(() => {
      chunk = 'top';
      wrapper = getWrapper();
    });

    it('does not set the js-action-menu__button class on the button elm', () => {
      expect(wrapper.get('button').classes()).not.toContain('js-action-menu__button');
    });

    it('does not render a list of action menu items', () => {
      expect(wrapper.find('ul').exists()).toBeFalsy();
    });
  });

  describe('when the "chunk" prop is set to "full"', () => {
    beforeEach(() => {
      chunk = 'full';
      wrapper = getWrapper();
    });

    it('sets the js-action-menu__button class on the button elm', () => {
      expect(wrapper.get('button').classes()).toContain('js-action-menu__button');
    });

    it('renders a list of action menu items', () => {
      expect(wrapper.find('ul').exists()).toBeTruthy();
    });

    describe('with an entry that is not individually-assignable', () => {
      beforeEach(() => {
        entry.individually_assignable = false;
        wrapper = getWrapper();
      });

      it( 'sets the label of the edit-status menu item to "Assign to Individual Students"', () => {
        expect(wrapper.get('.test-edit-status-menu-item').text()).toEqual(
          'Assign to Individual Students'
        );
      });

      it('calls the startEditing function of the datastore, passing in the assignable_id of the ' +
         'current entry when the edit-status menu item is clicked', async () => {
        spyOn(datastore, 'startEditing');
        const menuItem = wrapper.get('.test-edit-status-menu-item');
        await menuItem.trigger('click');

        expect(datastore.startEditing).toHaveBeenCalledWith(entry.assignable_id);
      });

      it('does not display a menu item for selecting all students', () => {
        expect(wrapper.find('.test-check-all-menu-item').exists()).toBeFalsy();
      });

      it('does not display a menu item for de-selecting all students', () => {
        expect(wrapper.find('.test-uncheck-all-menu-item').exists()).toBeFalsy();
      });

      it('does not display a menu item for enabling individual due dates', () => {
        expect(wrapper.find('.test-toggle-individual-due-dates').exists()).toBeFalsy();
      });
    });

    describe('with an individually-assignable entry', () => {
      beforeEach(() => {
        entry.individually_assignable = true;
        wrapper = getWrapper();
      });

      it('sets the label of the edit-status menu item to "Assign to Entire Section"', () => {
        expect(wrapper.get('.test-edit-status-menu-item').text()).toEqual(
          'Assign to Entire Section'
        );
      });

      it('calls the startEditing function of the datastore, passing in the assignable_id of the ' +
         'current entry when the edit-status menu item is clicked', async () => {
        spyOn(datastore, 'startEditing');
        const menuItem = wrapper.get('.test-edit-status-menu-item');
        await menuItem.trigger('click');

        expect(datastore.startEditing).toHaveBeenCalledWith(entry.assignable_id);
      });

      it('displays a menu item for selecting all students', () => {
        expect(wrapper.find('.test-check-all-menu-item').exists()).toBeTruthy();
      });

      it('calls the checkAll function of the datastore, passing in the assignable_id of the ' +
         'current entry when the check-all menu item is clicked', async () => {
        spyOn(datastore, 'checkAll');
        const menuItem = wrapper.get('.test-check-all-menu-item');
        await menuItem.trigger('click');

        expect(datastore.checkAll).toHaveBeenCalledWith(entry.assignable_id);
      });


      it('displays a menu item for de-selecting all students', () => {
        expect(wrapper.find('.test-uncheck-all-menu-item').exists()).toBeTruthy();
      });

      it('calls the uncheckAll function of the datastore, passing in the assignable_id of the ' +
         'current entry when the uncheck-all menu item is clicked', async () => {
        spyOn(datastore, 'uncheckAll');
        const menuItem = wrapper.get('.test-uncheck-all-menu-item');
        await menuItem.trigger('click');

        expect(datastore.uncheckAll).toHaveBeenCalledWith(entry.assignable_id);
      });
    });
  });
});
