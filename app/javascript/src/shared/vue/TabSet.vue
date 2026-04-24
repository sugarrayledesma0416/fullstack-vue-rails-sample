<template>
  <div
    class="c-tabset"
    :class="props.variant">
    <div
      class="tabs"
      role="tablist"
      :aria-label="props.label"
      :class="testClass('tab-list')">
      <template v-for="tab in tabs" :key="tab.label">
        <a
          href="javascript://"
          @click="switchToTab(tab.label, $event)"
          class="c-no-buttton  tab"
          role="tab"
          :aria-selected="tab.selected ? 'true' : 'false'"
          :class="[
            { 'is-selected': tab.selected },
            tab.linkClasses]">
          {{ tab.label }}
        </a>
      </template>
      <slot name="print" />
    </div>
    <slot></slot>
  </div>
</template>

<script>
  import { inject } from 'vue';
  import { testClass } from 'music';

  export default {
    name: 'TabSet',
    props: {
      label: { required: true, type: String },
      variant: { required: false, type: String },
    },
    setup(props) {
      const tabs = inject('tabs');

      function switchToTab(label, event) {
        // Remove focus from clicked link so it doesn't maintain a blue
        // border after tab switching occurs.
        event.target.blur();
        tabs.forEach(
          (tab) => { tab.selected = (tab.label === label); }
        );
      }

      return { props, switchToTab, tabs, testClass };
    }
  };
</script>

<style scoped>
  .tabs {
    display: -webkit-flex;
    display: -ms-flexbox;
    display: flex;
    -webkit-flex-wrap: wrap;
    -ms-flex-wrap: wrap;
    flex-wrap: wrap;
    -webkit-justify-content: flex-start;
    -ms-flex-pack: start;
    justify-content: flex-start;
    -webkit-align-items: flex-start;
    -ms-flex-align: start;
    align-items: flex-start;
    margin-bottom: 1rem;
    border-bottom: 0.0625rem solid var(--ui-neutral-medium, #ccc);
  }

  .tabs > * {
    margin-right: 1rem;
    margin-bottom: 0;
  }

  .tabs > *:last-child {
    margin-right: 0;
  }

  .tab {
    color: #333;
    text-transform: uppercase;
    padding: 0.5rem 1rem;
    position: relative;
    top: 0.0625rem;
  } 

  .tab.is-selected {
    color: #333;
    font-weight: bold;
    border-bottom: 0.25rem solid #FF6028;
  }

  .tab:hover {
    color: #333;
    text-decoration: none;
  }

  .supersites-jr .tab {
    color: var(--ui-link-color);
  }

  .supersites-jr .tab.is-selected {
    color: var(--ui-link-color);
    border-bottom: 0.25rem solid var(--ui-accent-color);
  }

  .supersites-jr .tab:hover {
    color: var(--ui-link-color);
  }

</style>
