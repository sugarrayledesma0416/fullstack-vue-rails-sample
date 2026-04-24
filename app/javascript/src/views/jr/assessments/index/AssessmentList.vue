  <!--
    Note: roles are set on the table cells because their `display` value
    gets changed in the CSS, and doing that changes element semantics.
  -->
<template>
  <div class="c-box  c-box--lozenge">
    <div class="u-oflow-x-hid">
      <div class="c-table-wrapper  c-table-wrapper--jr">
        <table class="c-table  c-table--jr">
          <thead>
            <tr class="c-header-row  c-header-row--jr">
              <th class="c-header-cell" scope="col" role="columnheader">
                Assessment
              </th>
              <th class="c-header-cell" scope="col">
                Due Date
              </th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="(assessment, index) in assessments"
              :key="assessment.link"
              class="c-row  c-row--jr"
              :class="testClass(`assessment-${index}`)">
              <th
                class="c-cell"
                scope="row"
                role="rowheader">
                <a
                  :class="testClass('assessment-link')"
                  :href="assessment.link">
                  {{ assessment.title }}
                </a>
              </th>
              <td class="c-cell" role="cell" :class="testClass('due-date')">
                <span class="c-due-label">Due</span>
                {{ assessment.due_date }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script>
  import { testClass } from 'music';

  export default {
    name: 'AssessmentList',
    props: {
      assessments: { default: () => [], type: Array },
    },
    setup() {
      return { testClass };
    },
  };
</script>

<style lang="sass" scoped>
@import '~MusicAssets/stylesheets/music/library/v1/base/main';

.c-box--lozenge {
  box-shadow: 0 0 8px 2px rgba(0,0,0,0.3);
  border-radius: 1rem;
  overflow: hidden;
  padding: 0;
}

/* ======== Table styles START ======== */

.c-table-wrapper--jr {
  overflow-x: auto; /* Scroll on horizontal overflow */
  padding: 0;
}

/* Give table styles a little specificity bump using the wrapper: */
.c-table-wrapper {

  .c-table--jr {
    --indent: 1rem;
    --cell-padding: 0 0.5rem 0 var(--indent);
  }

  .c-cell,
  .c-header-cell {
    --cell-padding: 1rem 0.5rem 1rem var(--indent);
    display: block; /* Stack cells */
    padding: var(--cell-padding);
    border: 0;
  }

  .c-header-cell {
    font-weight: normal;
    color: var(--ui-text-color);
    background-color: var(--ui-primary-medium);
    font-size: var(--font-4);
  }

  .c-header-cell + .c-header-cell {
    display: none; /* Hide all but the first column header */
  }

  .c-row--jr:hover > .c-cell {
    background-color: var(--ui-highlight-color);
  }

  .c-cell {
    &:first-child {
      --cell-padding: 1rem 0.25rem 0 var(--indent);
    }

    &:last-child {
      --cell-padding: 0 1rem 1rem var(--indent);
      border-bottom: rpx(1) solid #{$gray-e};
    }
  }

  .c-row--jr:last-child > .c-cell:last-child  {
    border-bottom: 0;
    padding-bottom: 0.5rem;
  }

  @include viewport-min(sm) {
    .c-cell,
    .c-header-cell,
    .c-header-cell + .c-header-cell {
      display: table-cell;
    }

    .c-row:not(:last-child) > .c-cell {
      border-bottom: rpx(1) solid #{$gray-e};
    }

    .c-cell {
      &:first-child {
        width: 99%; /* First column takes up any free space */
        --cell-padding: 1rem 0.25rem 1rem var(--indent);
      }
      &:last-child {
        --cell-padding: 1rem 1rem 1rem 0.25rem;
        white-space: nowrap;
      }
    }

    .c-cell,
    .c-header-cell {
      --indent: 1.5rem;

      &:first-child {
        padding-left: var(--indent);
      }

      &:last-child {
        padding-left: 2rem;
        padding-right: var(--indent);
      }
    }

    .c-header-cell {
      padding-top: 1.25rem;
      padding-bottom: 1.25rem;
      white-space: nowrap;
    }

    .c-due-label {
      display: none;
    }
  }
} /* / table-wrapper */

/* ==== Table styles END ==== */
</style>
