import { reactive } from 'vue';
import { mount } from '@vue/test-utils';
import * as ajaxUtils from 'shared/ajax_utils';
import fetchMock from 'fetch-mock';

import StudentNotificationListApp from 'features/notifications/StudentNotificationListApp';

describe(
  'StudentNotificationListApp',
  () => {
    let wrapper;

    const endpointUrl = '/notifications/list.json';
    const listType = 'announcements';
    const newAnnouncement = {
      created_at: '5 days ago',
      id: 123,
      label: 'new announcement label',
      language: 'es',
      path: '/path/to/announcement/123',
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
    const jsonResponse = {
      announcements: { new: [newAnnouncement], viewed: [viewedAnnouncement] },
      notifications: { new: [], viewed: [] },
    };

    function getWrapper() {
      return mount(
        StudentNotificationListApp,
        {
          props: { listType: listType, sourceUrl: endpointUrl }
        }
      );
    }

    beforeEach(
      () => {
        spyOn(ajaxUtils, 'getFromEndpoint').and.callThrough();
        fetchMock.mock(endpointUrl, { status: 200, body: jsonResponse });
      }
    );

    afterEach(() => { fetchMock.restore(); })

    describe(
      'when the app is mounted',
      () => {
        beforeEach(
          async () => {
            wrapper = getWrapper();
            await fetchMock.flush(true);
          }
        );

        it(
          'requests a collection of notifications from the sourceUrl ' +
          'specified in the props',
          () => {
            expect(ajaxUtils.getFromEndpoint).toHaveBeenCalledWith(
              endpointUrl, jasmine.any(Function)
            );
          }
        );

        it(
          'assigns the results of the fetch request and passes the data ' +
          'down into the NotificationListTable instances',
          () => {
            const tables = wrapper.findAllComponents({ name: 'NotificationListTable' });

            expect(tables[0].vm.entries).toEqual([newAnnouncement]);
            expect(tables[1].vm.entries).toEqual([viewedAnnouncement]);
          }
        );
      }
    );
  }
);
