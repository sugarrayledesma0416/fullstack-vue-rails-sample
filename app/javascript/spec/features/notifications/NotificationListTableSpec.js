import { reactive } from 'vue';
import { mount } from '@vue/test-utils';

import NotificationListTable from 'features/notifications/NotificationListTable';

describe(
  'NotificationListTable',
  () => {
    let wrapper;
    let data;
    let announcements;

    const entriesKey = 'new';
    const listType = 'announcements';
    const pageSize = 2;

    const newAnnouncement1 = {
      created_at: '5 days ago',
      id: 123,
      label: 'new announcement label',
      language: 'es',
      path: '/path/to/announcement/123',
      class_cancelled: false,
    };
    const newAnnouncement2 = {
      created_at: '5 days ago',
      id: 124,
      label: 'new announcement label',
      language: 'es',
      path: '/path/to/announcement/124',
      class_cancelled: false,
    };
    const viewedAnnouncement = {
      created_at: '5 days ago',
      id: 456,
      label: 'viewed announcement label',
      language: 'es',
      path: '/path/to/announcement/456',
      class_cancelled: false,
    };
    const newNotification = {
      created_at: '5 days ago',
      id: 234,
      label: 'new notification label',
      language: 'es',
      path: '/path/to/notification/234',
      class_cancelled: false,
    };
    const viewedNotification = {
      created_at: '5 days ago',
      id: 567,
      label: 'viewed notification label',
      language: 'es',
      path: '/path/to/notification/567',
      class_cancelled: false,
    };

    function getWrapper() {
      return mount(
        NotificationListTable,
        {
          props: { listType: listType, pageSize: pageSize, entriesKey: entriesKey },
          global: { provide: { data: data } }
        }
      );
    }

    beforeEach(
      () => {
        data = {
          entries: {
            announcements: {
              new: [newAnnouncement1], viewed: [viewedAnnouncement]
            },
            notifications: {
              new: [newNotification], viewed: [viewedNotification]
            }
          }
        };
        announcements = data.entries.announcements;
      }
    );

    it(
      'displays only notifications for the specified listType and ' +
      'entriesKey',
      () => {
        wrapper = getWrapper();
        expect(
          wrapper.find(`.test-notification-${ newAnnouncement1.id }`).exists()
        ).toBeTruthy();
        expect(
          wrapper.find(`.test-notification-${ viewedAnnouncement.id }`).exists()
        ).toBeFalsy();
        expect(
          wrapper.find(`.test-notification-${ newNotification.id }`).exists()
        ).toBeFalsy();
        expect(
          wrapper.find(`.test-notification-${ viewedNotification.id }`).exists()
        ).toBeFalsy();
      }
    );

    it(
      'does not display pagination controls when there are fewer ' +
      'entries than the specified page size',
      () => {
        wrapper = getWrapper();
        expect(wrapper.find('.test-page-list').exists()).toBeFalsy();
      }
    )

    it(
      'does not display pagination controls when the number of ' +
      'entries is equal to the specified page size',
      () => {
        announcements.new.push(newAnnouncement2);

        wrapper = getWrapper();
        expect(wrapper.find('.test-page-list').exists()).toBeFalsy();
      }
    );

    describe(
      'when there are more entries than the specified page size',
      () => {
        const newAnnouncement3 = {
          created_at: '5 days ago',
          id: 125,
          label: 'new announcement label',
          language: 'es',
          path: '/path/to/announcement/124',
          class_cancelled: false,
        };

        beforeEach(
          () => {
            announcements.new.push(newAnnouncement2, newAnnouncement3);
            wrapper = getWrapper();
          }
        );

        it(
          'displays pagination controls',
          () => {
            expect(wrapper.find('.test-page-list').exists()).toBeTruthy();
          }
        );

        it(
          'does not render a link for the first page',
          () => {
            const elm = wrapper.get('.test-page-number-1');

            expect(elm.element.localName).toEqual('span');
            expect(elm.classes()).toContain('notifications-current-page');
          }
        );

        it(
          'renders a link for subsequent pages',
          () => {
            const elm = wrapper.get('.test-page-number-2');

            expect(elm.element.localName).toEqual('a');
            expect(elm.classes()).not.toContain('notifications-current-page');
          }
        );

        it(
          'displays only the entries up to the specified pageSize',
          () => {
            expect(
              wrapper.find(`.test-notification-${ newAnnouncement1.id }`).exists()
            ).toBeTruthy();
            expect(
              wrapper.find(`.test-notification-${ newAnnouncement2.id }`).exists()
            ).toBeTruthy();
            expect(
              wrapper.find(`.test-notification-${ newAnnouncement3.id }`).exists()
            ).toBeFalsy();
          }
        );

        describe(
          'clicking on the link for a page number',
          () => {
            beforeEach(
              async () => {
                const page2Link = wrapper.get('.test-page-number-2');
                await page2Link.trigger('click');
              }
            );

            it(
              'does not render a link for the clicked page',
              () => {
                const elm = wrapper.get('.test-page-number-2');

                expect(elm.element.localName).toEqual('span');
                expect(elm.classes()).toContain('notifications-current-page');
              }
            );

            it(
              'renders a link for pages other than the cicked page',
              () => {
                const elm = wrapper.get('.test-page-number-1');

                expect(elm.element.localName).toEqual('a');
                expect(elm.classes()).not.toContain('notifications-current-page');
              }
            );

            it(
              'displays only the entries that belong on the clicked page',
              () => {
                expect(
                  wrapper.find(`.test-notification-${ newAnnouncement1.id }`).exists()
                ).toBeFalsy();
                expect(
                  wrapper.find(`.test-notification-${ newAnnouncement2.id }`).exists()
                ).toBeFalsy();
                expect(
                  wrapper.find(`.test-notification-${ newAnnouncement3.id }`).exists()
                ).toBeTruthy();
              }
            );
          }
        );
      }
    );

    describe(
      'when there are no notifications for the specified listType and ' +
      'entriesKey',
      () => {
        beforeEach(
          () => {
            announcements.new = [];
            wrapper = getWrapper();
          }
        );

        it(
          'displays a message that there are no notifications',
          () => {
            const message = wrapper.get('.test-no-entries-message');

            expect(message.text()).toEqual('There are no new announcements.')
          }
        );

        it(
          'does not display a table of notifications',
          () => {
            expect(wrapper.find('table').exists()).toBeFalsy();
          }
        );

        it(
          'does not display pagination controls',
          () => {
            expect(wrapper.find('.test-page-list').exists()).toBeFalsy();
          }
        );
      }
    );
  }
);
