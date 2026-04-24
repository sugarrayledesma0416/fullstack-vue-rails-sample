<template>
  <TabSet :label="props.listType" :variant="props.variant">
    <TabSetTab label="New">
      <NotificationListTable
        entriesKey="new"
        :listType="props.listType"
        :pageSize="Number(props.pageSize)" />
    </TabSetTab>
    <TabSetTab label="Viewed">
      <NotificationListTable
        entriesKey="viewed"
        :listType="props.listType"
        :pageSize="Number(props.pageSize)" />
    </TabSetTab>
  </TabSet>
</template>

<script>
  import { onMounted, provide, reactive } from 'vue';
  import * as ajaxUtils from 'shared/ajax_utils';
  import TabSet from 'shared/vue/TabSet';
  import TabSetTab from 'shared/vue/TabSetTab';
  import NotificationListTable from './NotificationListTable';

  export default {
    name: 'StudentNotificationListApp',
    components: { TabSet, TabSetTab, NotificationListTable },
    props: {
      listType: { required: true, type: String },
      // Even though pageSize should be a Number, the initial props
      // are passed in by calling rootElm.dataset, which will always
      // return strings.
      pageSize: { required: false, type: String, default: '10' },
      sourceUrl: { required: true, type: String },
      variant: { required: false, type: String, default: '' },
    },
    setup(props) {
      const data = reactive(
        {
          entries: {
            announcements: { new: [], viewed: [] },
            notifications: { new: [], viewed: [] },
          },
        }
      );
      const tabs = reactive(
        [
          { label: 'New', selected: true },
          { label: 'Viewed', selected: false },
        ]
      );

      provide('tabs', tabs);
      provide('data', data);

      async function fetchData() {
        ajaxUtils.getFromEndpoint(
          props.sourceUrl,
          (response) => {
            data.entries = response;
          }
        );
      };

      onMounted(fetchData);

      return { props };
    },
  };
</script>
