<template>
  <h3 class="content-filter">
    Units
  </h3>
  <!-- eslint-disable vue/no-multiple-template-root -->
  <MultiSelect
    type="unit"
    :data="tocItems"
    :resetAll="true"
    :selectedOption="selectedUnit"
    @update:selectedItems="handleSelectedUnits"
    @update:deselectAll="deselectAllUnits" />
  <!-- eslint-enable vue/no-multiple-template-root -->
</template>

<script setup>
  import { inject, onMounted, reactive, ref, watchEffect } from 'vue';
  import useStandardsAssigningStore from './../models/use_standards_assigning_store.js';
  import MultiSelect from './MultiSelect.vue';

  defineProps({
    programTocType: { required: true, type: String },
    tocItems: { required: true, type: Array },
  });

  const store = useStandardsAssigningStore();

  const selectedUnit = inject('selectedUnit');
  const selectedUnitsCheckbox = reactive([]);

  const emit = defineEmits(['applyFilter']);
  const isMounted = ref(false);

  const handleSelectedUnits = (event) => {
    const itemId = Number(event.value);
    if (event.isChecked) {
      if (!selectedUnitsCheckbox.includes(itemId)) {
        selectedUnitsCheckbox.push(itemId);
      }
    } else {
      selectedUnitsCheckbox.splice(selectedUnitsCheckbox.indexOf(itemId), 1);
    }

    store.selectedTocItems = [...selectedUnitsCheckbox];
    if (store.selectedTocItems.length === 0) {
      store.setDefaultSelectedTocItems();
    }

    if (!event.defaultSelected) {
      emit(
        'applyFilter',
        [...selectedUnitsCheckbox], store.selectedSkills, store.selectedRefinements
      );
    }
  };

  const deselectAllUnits = () => {
    selectedUnitsCheckbox.length = 0;
    store.setDefaultSelectedTocItems();
    emit('applyFilter', []);
  };

  watchEffect(() => {
    if (isMounted.value && store.selectedTocItems.length === 0) {
      deselectAllUnits();
    }
  });

  onMounted(() => {
    isMounted.value = true;
  });
</script>

<style lang="scss" scoped>
  @use 'music/app/styles/library/base';
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .content-filter {
    color: $lightest-text;
    font-size: rpx(16);
    font-weight: normal;
    letter-spacing: rpx(1);
    margin-bottom: rpx(5);
    text-transform: uppercase;
  }
</style>
