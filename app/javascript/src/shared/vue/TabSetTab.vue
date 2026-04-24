<template>
  <div v-show="tab.selected">
    <slot></slot>
  </div>
</template>

<script>
  import { inject } from 'vue';

  export default {
    name: 'TabSetTab',
    props: {
      label: { required: true, type: String },
    },
    setup(props) {
      const tabs = inject('tabs');
      const tab = tabs.find(
        (entry) => { return entry.label === props.label; }
      );

      return { tab };
    }
  };
</script>
