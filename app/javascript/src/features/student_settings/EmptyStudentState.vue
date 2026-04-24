<template>
  <div class="u-txt-ctr u-mar-top-80 u-width-full">
    <h4 class="c-heading-v3 c-heading-v3--4 u-txt-true-gray-600 u-mar-bot-16">No students enrolled</h4>
    <p v-if="props.rostering">Students will display here once they sync.</p>
    <p v-else>Add students in the <a class="u-txt-red-500" :href="props.rosterUrl">Roster</a> to begin<br/>customizing their learning needs.</p>
  </div>
</template>

<script setup>
const props = defineProps({
  rostering: {
    type: Boolean,
    required: true
  },
  rosterUrl: {
    type: String,
    required: true
  }
});
</script>
