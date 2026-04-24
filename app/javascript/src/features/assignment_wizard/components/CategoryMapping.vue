<template>
  <div class="category-mappings">
    <ModalComponent
      featureVariant="category-mappings"
      :class="testClass('category-mappings-modal')"
      @close="onCloseClick">
      <template #body>
        <div class="category-mappings__body">
          <div
            v-if="usingPredefinedTrack"
            class="category-mappings__title"
            :class="testClass('category-mappings__title')">
            For the activities in each Learning Group, choose a gradebook category.
          </div>
          <div
            v-else
            class="category-mappings__title"
            :class="testClass('category-mappings__title')">
            Associate the gradebook categories from the template to your course.
          </div>
          <table class="category-mappings__table">
            <thead>
              <tr v-if="usingPredefinedTrack" class="mapping-col-header">
                <th class="mappings-table__header" :class="testClass('mappings-table__header')">
                  Learning Group
                </th>
                <th class="mappings-table__header" :class="testClass('mappings-table__header')">
                  Gradebook Category
                </th>
              </tr>
              <tr v-else class="mappings-table__col-header">
                <th class="mappings-table__header" :class="testClass('mappings-table__header')">
                  Template
                </th>
                <th class="mappings-table__header" :class="testClass('mappings-table__header')">
                  Course
                </th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="group in categoryMappingList" :key="group" class="mappings-table__row">
                <td class="mappings-table__column">
                  <label
                    class="mappings-table__label"
                    :class="testClass('mappings-table__label')">
                    {{ group }}
                  </label>
                </td>
                <td>
                  <BasicSelect
                    testSelector="mappings-table__category-select"
                    :modelValue="getSelectedCategoryId(group)"
                    :options="prepareSelectOptions(group)"
                    @change="onCategoryChange($event, group)" />
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </template>
      <template #footer>
        <div class="category-mappings__controls">
          <VhlButton
            class="mar-rt-8  js-modal-a11y__last-focus-element"
            :class="testClass('modal-cancel')"
            @click="onCloseClick">
            Cancel
          </VhlButton>

          <VhlButton
            variant="primary"
            class="js-modal-a11y__last-focus-element"
            :class="testClass('save-category-mappings')"
            :disabled="isSaveDisabled"
            @click="onSaveClick">
            Save
          </VhlButton>
        </div>
      </template>
    </ModalComponent>
  </div>
</template>

<script>
  import { isObjEmpty } from 'shared/utils';
  import { testClass } from 'music';
  import { computed } from 'vue';
  import ModalComponent from 'features/modal/ModalComponent';
  import BasicSelect from 'music/app/javascript/src/components/basic_select/v1.0/BasicSelect';
  import VhlButton from 'features/learning_tracks/components/VhlButton';

  /**
   * @typeDef {PropObject}
   * @type {Object}
   * @property {Array} categoryMappingList - array of learning groups.
   * @property {Object} categories - categories to be mapped.
   * @property {Array} courseInfoCategories - categories in the Course.
   * @property {boolean} usingPredefinedTrack - whether to use predefined tracks
   */

  /**
   * This composable has methods for Category Mapping.
   * @param {Function} emit - Vue js emit Function.
   * @param {PropObject} props - Vue js props object.
   * @return {Object}
   */
  const useCategoryMapping = (emit, props) => {
    /**
     * Return the selected category id for a group.
     * @param {string} group - category group
     * @return {number} category id.
     */
    function getSelectedCategoryId(group) {
      const category = props.categories[group];
      return category?.id || 0;
    }

    /**
     * Handler for category change.
     * @param {Event} event - click event on category change.
     * @param {string} group - category group.
     */
    function onCategoryChange(event, group) {
      const category = props.courseInfoCategories.find((category) => {
        return category.id === parseInt(event.target.value);
      });
      props.categories[group] = category;
    }

    /**
     * Handler for modal close.
     * @param {Event} event - click event on close modal button.
     */
    function onCloseClick(event) {
      emit('close', event);
    }

    /**
     * Handler for save button click.
     * @param {Event} event - click event on save button click.
     */
    function onSaveClick(event) {
      emit('save', event);
    }

    /**
     * @typeDef {OptionObject}
     * @property {string} value - value for the default option tag.
     * @property {string} text - text for the default option tag.
     */

    /**
     * Prepare options data for the select tag.
     * @param {string} group - category group.
     * @return {Array.<OptionObject>} options
     */
    function prepareSelectOptions(group) {
      const options = [];
      const selectedCategoryId = getSelectedCategoryId(group);
      if (selectedCategoryId === 0) {
        options.push({ value: '', text: '' });
      }

      props.courseInfoCategories.forEach((category) => {
        options.push({
          value: category.id,
          text: category.name,
        });
      });
      return options;
    }

    return {
      getSelectedCategoryId,
      onCategoryChange,
      onCloseClick,
      onSaveClick,
      prepareSelectOptions,
    };
  };

  export default {
    name: 'CategoryMapping',
    components: { ModalComponent, VhlButton, BasicSelect },
    props: {
      categoryMappingList: { required: true, type: Array },
      categories: { required: true, type: Object },
      courseInfoCategories: { required: true, type: Array },
      usingPredefinedTrack: { required: true, type: Boolean },
    },
    emits: ['close', 'save'],
    setup(props, { emit }) {
      const {
        getSelectedCategoryId, onCategoryChange, onCloseClick, onSaveClick, prepareSelectOptions,
      } = useCategoryMapping(emit, props);

      const isSaveDisabled = computed(
        () => {
          let disabled = false;
          for (let i = 0; i < props.categoryMappingList.length; ++i) {
            const categoryGroup = props.categoryMappingList[i];
            const category = props.categories[categoryGroup];
            if (isObjEmpty(category) || category.id === null) {
              disabled = true;
              break;
            }
          }
          return disabled;
        }
      );

      return {
        isSaveDisabled,
        getSelectedCategoryId,
        onCategoryChange,
        onCloseClick,
        onSaveClick,
        prepareSelectOptions,
        testClass,
      };
    },
  };
</script>

<style lang="scss" scoped>

 .category-mappings {
    color: #333;
  }

  .category-mappings__title {
    font-size: 0.6875rem;
    text-align: center;
    margin-bottom: 0.8125rem;
  }

  .category-mappings__table {
    border-collapse: collapse;
    font-size: inherit;
    margin: 0;
    padding: 0;
    width: 100%;
  }

  .mappings-table__col-header {
    border-bottom: none;
    border-spacing: 0;
  }

  .mappings-table__header {
    border: 0;
    border-spacing: 0;
    color: #565656;
    font-size: 0.6875rem;
    font-weight: bold;
    padding: 0.1875rem;
    text-align: left;
  }

  .mappings-table__row {
    border-bottom: 0.0625rem dotted #919191;
  }

  .mappings-table__column {
    border: 0;
    height: 1.875rem;
    margin: 0;
    padding: 0.1875rem;
    text-align: left;
  }

  .mappings-table__label {
    color: #565656;
    display: block;
    font-size: 0.6875rem;
    font-weight: normal;
    margin: 0;
    margin-bottom: 0.1875rem;
    padding: 0;
    size: 0.6875rem;
  }

  .category-mappings__controls {
    display: flex;
    flex-wrap: wrap;
    justify-content: flex-end;
    line-height: 2rem;
    margin: 0;
    text-align: right;
  }

  .mar-rt-8 {
    margin-right: 0.5rem;
  }
</style>
