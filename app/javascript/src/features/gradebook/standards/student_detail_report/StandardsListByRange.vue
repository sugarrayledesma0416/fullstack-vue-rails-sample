<template>
  <div class="standard-table">
    <table class="c-table  standard-table__container">
      <thead>
        <tr class="c-header-row">
          <th
            scope="col"
            :class="`icon-${sortDirection.list['label'].direction}`"
            @click="sortStandardList('label', sortDirection.list['label'].value)"
            :aria-sort="sortDirection.list['label'].direction">
            <tippy
              :content="props.tooltipInfo.standardsAssessed.text"
              :placement="props.tooltipInfo.standardsAssessed.position">
              Standards Assessed
                <vhl-column-ascending-icon
                v-if="sortDirection.list['label'].direction === 'ascending'"
                size="md"
                rotate="0" />
              <vhl-column-descending-icon
                v-if="sortDirection.list['label'].direction === 'descending'"
                size="md"
                rotate="0" />
              <vhl-column-unsorted-icon
                v-if="sortDirection.list['label'].direction === 'unsorted'"
                size="md"
                rotate="0"/>
            </tippy>
          </th>
          <th
            scope="col"
            :class="[
              'u-txt-rt',
              `icon-${sortDirection.list['percent_correct'].direction}`]"
            @click="sortStandardList('percent_correct', sortDirection.list['percent_correct'].value)"
            :aria-sort="sortDirection.list['percent_correct'].direction">
            <tippy
              :content="props.tooltipInfo.percentage.text"
              :placement="props.tooltipInfo.percentage.position">
              %
              <vhl-column-ascending-icon
                v-if="sortDirection.list['percent_correct'].direction === 'ascending'"
                size="md"
                rotate="0" />
              <vhl-column-descending-icon
                v-if="sortDirection.list['percent_correct'].direction === 'descending'"
                size="md"
                rotate="0" />
              <vhl-column-unsorted-icon
                v-if="sortDirection.list['percent_correct'].direction === 'unsorted'"
                size="md"
                rotate="0"/>
            </tippy>
          </th>
          <th
            scope="col"
            :class="[
              'u-txt-rt',
              'u-pad-rt-32',
              `icon-${sortDirection.list['items_count'].direction}`]"
            @click="sortStandardList('items_count', sortDirection.list['items_count'].value)"
            :aria-sort="sortDirection.list['items_count'].direction">
            <tippy
              :content="props.tooltipInfo.items.text"
              :placement="props.tooltipInfo.items.position">
              Items
              <vhl-column-ascending-icon
                v-if="sortDirection.list['items_count'].direction === 'ascending'"
                size="md"
                rotate="0" />
              <vhl-column-descending-icon
                v-if="sortDirection.list['items_count'].direction === 'descending'"
                size="md"
                rotate="0" />
              <vhl-column-unsorted-icon
                v-if="sortDirection.list['items_count'].direction === 'unsorted'"
                size="md"
                rotate="0"/>
            </tippy>
          </th>
        </tr>
      </thead>
      <tbody v-if="hasDataToShow">
        <tr
          v-for="(standardByRangeValue, standardByRangeKey) in props.standardListByRange"
          :key="standardByRangeKey"
          class="c-row"
          :class="[
            testClass('standard-list-item'),
            {'is-active' : activeState.active[standardByRangeKey]}]"
          @click="setSelectedStandardDetails(standardByRangeValue, standardByRangeKey)">
          <td>
            <a href="javascript://" >
              {{ standardByRangeValue.label }}
            </a>
          </td>
          <td class="u-txt-rt">
            {{
              standardByRangeValue.percent_correct % 1 === 0
                ? standardByRangeValue.percent_correct
                : standardByRangeValue.percent_correct.toFixed(2)
            }}%
          </td>
          <td class="u-txt-rt  u-pad-rt-32">
            {{ standardByRangeValue.items_count }}
          </td>
        </tr>
      </tbody>
      <tbody v-else>
        <tr class="c-row">
          <td colspan="3" class="u-txt-ctr">
            <span>No standards found.</span>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
<script setup>
  import { testClass } from 'music';
  import { onMounted, reactive, computed, ref, watch } from 'vue';
  import { Tippy } from 'vue-tippy';
  import MusicIcon from 'shared/vue/MusicIcon';

  const props = defineProps({
    standardListByRange: { required: true, type: Object },
    tooltipInfo: { required: true, type: Object },
    selectedStandardGuid: { type: String, default: '' },
  });
  const activeState = reactive({ active: {}});

  const hasDataToShow = computed(() => {
    return Object.keys(props.standardListByRange).length > 0;
  });

  const sortDirection = reactive({
    list: {
      label: { value: true, direction: 'unsorted'},
      percent_correct: { value: true, direction: 'unsorted'},
      items_count: { value: true, direction: 'unsorted'},
    }
  });

  const emit = defineEmits(['getStandardDetails', 'sortStandardList']);

  onMounted(function() {
    resetIsActiveState();
  });

  watch(() => props.standardListByRange, (newValue) => {
    Object.keys(props.standardListByRange).forEach((index) => {
      if (index === props.selectedStandardGuid) {
        setSelectedStandardDetails(props.standardListByRange[index], props.selectedStandardGuid);
      }
    });
  });

  /**
   * Reset the active state for category list.
   */
   function resetIsActiveState() {
    activeState.active = Object.keys(props.standardListByRange).reduce((element, key) => {
      element[key] = false;
      return element;
    }, {});
  }

  /**
   * Set active status to clicked category.
   * @param {string} key
   */
   function setActiveStatus(key) {
    resetIsActiveState();
    activeState.active[key] = true;
  }

  /**
   * emit sortStandardList event with sort param
   * @param {string} sortParam
   */
  function sortStandardList(sortParam, sortValue) {
    Object.keys(sortDirection.list).forEach(columnName => {
      if (sortParam !== columnName) {
        sortDirection.list[columnName].direction = 'unsorted';
        sortDirection.list[columnName].value = true;
      }
    });
    emit('sortStandardList', {
              'type': sortParam,
              'sort': sortDirection.list[sortParam].value = !sortValue,
            });
    sortDirection.list[sortParam].direction = sortDirection.list[sortParam].value  ? 'ascending' : 'descending';
    resetIsActiveState();
  }

  /**
   * Sets the selected standard details and emits an event with the standard data.
   * @param {string} selectedStandardGuid - The GUID of the selected standard.
   * @param {Object} standardData - The data of the standard.
  */
  function setSelectedStandardDetails(standardData, selectedStandardGuid) {
    emit('getStandardDetails', {
      'id': standardData.id,
      'label': standardData.label,
      'description': standardData.description,
      'standard_guid': selectedStandardGuid,
    });
    setActiveStatus(selectedStandardGuid);
  }

</script>
<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .standard-table {
    --is-active-background-color: #f5f8ff;
    display: flex;
    justify-content: center;

    &__container {
      margin-top: 2rem;
      width: 90%;

      th {
        color: $gray-3;
        cursor: pointer;
      }

      .c-header-row > th {
        padding: 1rem;
        border-bottom: $border-width-1 solid $white;
      }
      .c-row > td {
        cursor: pointer;
        padding: 1rem;
        border-bottom-color: $gray-c;
      }
      
      .is-active,
      .c-row:hover {
        background-color: var(--is-active-background-color);
      }
    }
  }
</style>
