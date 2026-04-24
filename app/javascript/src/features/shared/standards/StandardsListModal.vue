<template>
  <BasicDialog
    :isConfirmationDialog="false"
    :isModal="true"
    title="Standards List"
    :class="testClass('standard-list-modal')"
    @close-dialog="$emit('close', $event)">
    <template #body>
      <ul
        v-for="standards in standardsList"
        :key="standards"
        class="standard-set-list">
        <li>
          <h3
            class="c-header--caps  standard-set-display-name"
            :class="testClass('standard-set-display-name')">
            <!-- I'm using index '0' to get the standard item number because this is a no associative array. -->
            {{ standards[0] }}
          </h3>
          <ul class="standard-list">
            <!-- I'm using index '1' to get the standard list by set because this is a no associative array. -->
            <li
              v-for="standardListBySet in standards[1]"
              :key="standardListBySet.id"
              class="standard-item"
              :class="testClass('standard-item')">
              <details class="standards-disclosure">
                <summary>
                  <a
                    :href="`${instructorStandardsAssigningPath}?standards=${standardListBySet.id}&selected_unit=${unitId}`"
                    target="_blank"
                    class="search-standard-assigning"
                    :class="[testClass('search-standard-assigning'), 'js-dialog-a11y__last-focus-elm']">
                    <vhl-magnifying-glass-icon size="md"></vhl-magnifying-glass-icon>
                  </a>
                  <span
                    class="standard-item-number"
                    :class="testClass('standard-item-number')">
                    {{ standardListBySet.number }}
                  </span>
                  <music-icon-caret class="music-icon-caret" size="md" rotate="1"></music-icon-caret>
                </summary>
                <div
                  class="standard-description"
                  :class="testClass('standard-description')">
                  {{ standardListBySet.description }}
                </div>
              </details>
            </li>
          </ul>
        </li>
      </ul>
    </template>
  </BasicDialog>
</template>
<script setup>
  import BasicDialog from
  'music/app/javascript/src/components/basic_dialog/v1.0/BasicDialog.vue';
  import { testClass } from 'music';

  defineProps({
    standardsList: { required: true, type: Array },
    instructorStandardsAssigningPath: { required: true, type: String },
    unitId: { required: true, type: String },
  });

  defineEmits(['close']);
</script>

<style lang="scss" scoped>
  @use '~MusicAssets/stylesheets/music/library/v1/base/main' as *;

  .standard-set-list {
    .standard-set-display-name {
      color: $gray-6;
      font-weight: normal;
      margin: 1.5rem 0 0.5rem 0;
    }

    .standard-list {
      padding: 0;

      .standard-item {
        border-top: rpx(1) solid  $gray-e;

        &-number {
          color: $link-color;
        }
      }

      .standard-item:last-child {
        border-bottom: rpx(1) solid  $gray-e;
      }

      .standards-disclosure {
        width: 25rem;

        summary {
          display: flex;
          align-items: center;
          flex-direction: row;
          padding: 0.5rem 0;

          .search-standard-assigning {
            align-items: center;
            border-radius: rpx(5);
            box-shadow: rpx(1) rpx(2) rpx(5) 0 rgba($black, 0.25);
            display: flex;
            flex-direction: column;
            height: 2rem;
            justify-content: center;
            width: 2rem;

            &:hover {
              text-decoration: none;
            }
          }

          .standard-item-number {
            padding: 0 1rem;
          }
          .music-icon-caret :deep(.c-svg-icon > svg) {
            fill: $link-color;
          }
        }

        summary::after {
          content: '';
        }

        .standard-description {
          padding-left: 3rem;
          padding-bottom: 0.5rem;
        }
      }

      .standards-disclosure[open] > summary {
        .music-icon-caret {
          transform: rotate(180deg);
        }
      }
    }
  }

  @include theme('supersites-jr') {
    .standard-set-display-name {
      color: var(--ui-primary-darker);
      font-size: var(--font-3);
    }
  }
</style>
