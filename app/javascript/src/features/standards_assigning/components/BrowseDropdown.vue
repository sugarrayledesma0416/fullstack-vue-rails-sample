<template>
  <sl-dropdown ref="dropdownRef" sync="width">
    <sl-button
      slot="trigger"
      size="large"
      class="dropdown-label"
      caret>
      {{ truncatedLabel }}
    </sl-button>

    <sl-menu @sl-select="onSlSelect">
      <template v-for="(option, index) in options" :key="`opt-${index}`">
        <sl-menu-item
          :class="testClass(`option-${index}`)"
          :value="option">
          <slot name="option" :option="option">
            {{ option.value }}
          </slot>
        </sl-menu-item>
        <sl-divider
          v-if="showDivider && index < options.length - 1"
          class="divider" />
      </template>
    </sl-menu>
  </sl-dropdown>
</template>

<script setup>
  import { computed } from 'vue';
  import { testClass } from 'music';

  const props = defineProps({
    modelValue: { type: [String, Object, Number], default: null },
    options: { type: Array, required: true },
    maxLabelLength: { type: Number, default: 20 },
    placeholder: { type: String, default: 'Select an option' },
    showDivider: { type: Boolean, default: true },
  });

  const emit = defineEmits(['update:modelValue', 'select']);

  const truncatedLabel = computed(() => {
    if (!props.modelValue) return props.placeholder;

    const label = typeof props.modelValue === 'string' ?
      props.modelValue :
      props.modelValue.label;

    return label.length > props.maxLabelLength ?
      label.slice(0, props.maxLabelLength) + '…' :
      label;
  });

  /**
   * handle dropdown selection and emit events.
   * @param {Event} event
   */
  function onSlSelect(event) {
    const option = event.detail.item.value;
    emit('update:modelValue', option);
    emit('select', option);
  }
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .dropdown-label {
    width: 100%;
  }

  .divider {
    margin: 0;
  }

  sl-button::part(caret) {
    margin-left: auto;
  }
  
  sl-button::part(base) {
    text-transform: none;
    font-size: rpx(14);
  }

  sl-button::part(label) {
    padding-right: rpx(16);
  }

  sl-button::part(base):hover {
    background-color: $gray-f8;
    border-color: unset;
    color: unset;
  }

  sl-menu::part(base) {
    max-height: rpx(350);
    border-radius: rpx(4);
  }

  sl-menu-item::part(base) {
    white-space: normal;
  }
</style>
