<template>
  <template v-if="entries.length === 0">
    <p class="u-mar-bot-64" :class="testClass('no-entries-message')">
      There are no {{ props.entriesKey }} {{ props.listType }}.
    </p>
  </template>
  <template v-else>
    <nav v-if="shouldPaginate">
      <ul
        class="notifications-pagination-list"
        :class="testClass('page-list')">
        <li class="notifications-pagination-header">
          Page
        </li>
        <template v-for="pageNumber in Object.keys(pages)">
          <li class="notifications-page-number">
            <template v-if="pageNumber === currentPage.number">
              <span
                :aria-label="`Page ${ pageNumber }, current page`"
                :class="testClass(`page-number-${ pageNumber }`)"
                class="notifications-current-page">{{ pageNumber }}</span>
            </template>
            <template v-else>
              <a
                href="javascript://" 
                :aria-label="`Page ${ pageNumber }`"
                :class="testClass(`page-number-${ pageNumber }`)"
                @click="goToPage(pageNumber)">{{ pageNumber }}</a>
            </template>
          </li>
        </template>
      </ul>
    </nav>

    <div class="notifications-table-wrapper">
      <table
        class="notifications-table"
        data-page-element="notifications">
        <thead>
          <tr class="notifications-header-row">
            <th class="notifications-header-cell" scope="col">
              Title
            </th>
            <th class="notifications-header-cell" scope="col">
              Date Created
            </th>
          </tr>
        </thead>
        <tbody>
          <template v-for="entry in pages[currentPage.number]" :key="entry.id">
            <tr
              class="notifications-row"
              :class="testClass(`notification-${ entry.id }`)"
              :data-notification-id="entry.id">
              <td
                data-container="header_link"
                class="notifications-cell  u-txt-top">
                <span
                  v-if="entry.class_cancelled"
                  class="c-tag  c-tag--sm  u-mar-rt-10">
                  Class cancelled
                </span>
                <a
                  :id="`action_link_for_notification_${ entry.id }`"
                  :href="entry.path"
                  :lang="entry.language"
                  :class="testClass('notification-label')"
                  v-text="entry.label" />
                <span
                  :id="`a11y_notification_message_${ entry.id }`"
                  data-container="message"
                  class="u-txt-reg  u-mar-lt-10"
                  :class="testClass('notification-message')"
                  v-text="entry.message" />
              </td>
              <td
                :id="`a11y_notification_date_${ entry.id }`"
                data-container="creation_date"
                class="notifications-cell  creation_date  u-txt-top  u-txt-nowrap"
                :class="testClass('notification-date')">
                {{ entry.created_at }}
              </td>
            </tr>
          </template>
        </tbody>
      </table>
    </div>
  </template>
</template>

<script>
  import { computed, inject, reactive, watch } from 'vue';
  import { testClass } from 'music';

  export default {
    name: 'NotificationListTable',
    props: {
      entriesKey: { required: true, type: String },
      listType: { required: true, type: String },
      pageSize: { required: true, type: Number },
    },
    setup(props) {
      const data = inject('data');
      const pages = reactive({});
      const currentPage = reactive({ number: '1' });

      const entries = computed(
        () => {
          if (data.entries === {}) {
            return [];
          } else {
            return data.entries[props.listType][props.entriesKey];
          }
        }
      );

      const shouldPaginate = computed(
        () => {
          return entries.value.length > props.pageSize;
        }
      );

      function populatePages() {
        const pageCount = Math.ceil(entries.value.length / props.pageSize);
        for (let i = 0; i < pageCount; i++) {
          const start = i * props.pageSize;
          const end = start + props.pageSize;
          pages[i + 1] = entries.value.slice(start, end);
        }
      }

      function goToPage(pageNumber) {
        currentPage.number = pageNumber;
      }

      populatePages();

      watch(() => data.entries, populatePages);

      return {
        currentPage,
        entries,
        goToPage,
        pages,
        props,
        shouldPaginate,
        testClass,
      };
    },
  };
</script>

<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .notifications-page-number .notifications-current-page {
    font-weight: bold;
    border-bottom: 0.25rem solid var(--ui-accent-color);
  }

  .notifications-page-number > * {
    padding-left: 0.25rem;
    padding-right: 0.25rem;
  }

  .notifications-pagination-header {
    color: var(--ui-neutral-darkest);
  }

  .notifications-pagination-list {
    list-style-type: none;
    padding-left: 0;
    display: -webkit-flex;
    display: -ms-flexbox;
    display: flex;
    -ms-flex-wrap: wrap;
    flex-wrap: wrap;
    -webkit-justify-content: center;
    -ms-flex-pack: center;
    justify-content: center;
    -webkit-align-items: center;
    -ms-flex-align: center;
  }

  .notifications-pagination-list ul {
    list-style-type: none;
    padding-left: 1rem;
    margin-bottom: 0;
  }

  .notifications-pagination-list > * {
    margin-right: 0.5rem;
    margin-bottom: 0;
  }

  .notifications-pagination-list > *:last-child {
    margin-right: 0;
  }


  /* Announcements/Notifications table */

  .notifications-table-wrapper {
    margin: 0 1rem;
  }

  .notifications-table { width: 100%; }

  .notifications-header-row {
    background: transparent;
  }

  .notifications-header-cell {
    font-weight: normal;
    text-transform: uppercase;
    color: var(--ui-neutral-medium);
    display: none;
  }

  .notifications-cell {
    display: block;
    border-bottom: 0;
    line-height: 1.2;

    &:first-child {
      font-weight: bold;
      letter-spacing: 0.06em;
      padding-top: 0.3rem;
    }

    &:last-child {
      border-bottom: rpx(1) solid var(--ui-divider-color);
      padding-bottom: 0.3rem;
    }
  }

  .notifications-row:last-child {
    > .notifications-cell:last-child {
      border-bottom: 0;
    }
  }

  @include viewport-min(md) {
    .notifications-table-wrapper {
      margin: 0 2rem;
    }

    .notifications-header-cell,
    .notifications-cell {
      display: table-cell;
    }

    .notifications-cell {
      border-bottom: rpx(1) solid var(--ui-divider-color);
      line-height: inherit;

      &:first-child {
        width: 80%;
        padding: 0.5rem 0;
      }

      &:last-child {
        padding: 0.5rem 0;
      }
    }

    .notifications-row:last-child > .notifications-cell {
      border-bottom: 0;
    }

    /* Title column */
    .notifications-cell:nth-child(1) {
      padding-right: 1rem;
    }
  }

</style>
