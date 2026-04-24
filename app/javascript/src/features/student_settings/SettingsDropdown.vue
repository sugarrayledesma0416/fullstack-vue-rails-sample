<template>
  <sl-dropdown
    :data-testid="dataTestid"
    distance="4"
    class="u-mar-rt-20"
    :disabled="disabled"
    :aria-label="ariaLabel"
    @sl-show="handleDropdownShow"
    @sl-hide="handleDropdownHide"
  >
  <!-- This component does something a bit unusual here - we hide our tooltip when the button is not
   disabled by turning it into a simple div. This is solely to avoid duplicating the "button" below
   inside a v-if v-else block where we conditionally render the sl-tooltip or the div depending on
   the disabled prop.  It's just more concise. -->
    <component :is="disabled ? 'sl-tooltip' : 'div'"
      :content="tooltipContent"
      data-testid="settings-dropdown-trigger"
      slot="trigger"
    >
      <button
        class="c-button-v3 c-button-v3--tertiary c-button-v3--xs"
        role="combobox"
        aria-haspopup="true"
        :disabled="disabled"
        :aria-expanded="isExpanded"
      >
        <span>{{ buttonLabel }}</span>
        <!-- This key is necessary to force the icon out of static rendering mode in Vue.
         Because we're loading untitled-ui dynamically, the icon doesn't properly get rendered if
         it's statically rendered. -->
        <sl-icon :key="`chevronDown-${disabled}`" name="chevron-down" library="untitled-ui" />
      </button>
    </component>
    <sl-menu @sl-select="handleSelect">
      <slot />
    </sl-menu>
  </sl-dropdown>
</template>

<script setup>
  import { ref, computed } from 'vue';

  const props = defineProps({
    dataTestid: {
      type: String,
      required: true
    },
    ariaLabel: {
      type: String,
      required: true
    },
    buttonLabel: {
      type: String,
      required: true
    },
    disabled: {
      type: Boolean,
      default: false
    }
  });

  const emit = defineEmits(['select']);

  const isExpanded = ref(false);

  const tooltipContent = computed(() =>
    props.disabled ? 'Select at least one student to apply settings.' : undefined
  );

  const handleDropdownShow = () => {
    isExpanded.value = true;
  };

  const handleDropdownHide = () => {
    isExpanded.value = false;
  };

  const handleSelect = (event) => {
    if (!props.disabled) {
      emit('select', event);
    }
  };
</script>
