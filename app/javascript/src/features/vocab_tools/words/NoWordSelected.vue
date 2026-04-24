<template>
  <div class="c-no-words-selected">
    <div>
      <img 
        aria-hidden="true"
        :src="magnifyingGlassIconPath"/>
    </div>
    <div>
      <div class="c-no-words-selected__msg" :class="testClass('no-words-selected__msg')"> You have no words selected.</div>
      <div class="c-no-words-selected__direction"> Select the words under the lessons on the left.</div>
    </div>
  </div>
</template>

<script>
  import { inject } from 'vue';
  import { testClass } from 'music';
  export default {
    name: 'NoWordSelected',
    setup() {
      const magnifyingGlassIconPath = inject('magnifyingGlassIconPath');
      return { magnifyingGlassIconPath, testClass };
    }
  };
</script>
