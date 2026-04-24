<template>
  <sl-dialog :class="dialogClass" style="--width: 600px;">
    <span slot="label" class="c-heading-v3 c-heading-v3--2 u-txt-true-gray-600">{{ title }}</span>
    <img :src="imageSrc" :alt="title" class="u-mar-bot-24 u-width-full">
    <div slot="footer" class="u-dis-flex u-justify-content-center">
      <button class="c-button-v3 c-button-v3--primary" slot="footer" @click="closeDialog">Close</button>
    </div>
  </sl-dialog>
</template>

<script setup>
const props = defineProps({
  title: {
    type: String,
    required: true
  },
  imageSrc: {
    type: String,
    required: true
  },
  dialogClass: {
    type: String,
    required: true
  }
});

function closeDialog() {
  const dialogElement = document.querySelector(`.${props.dialogClass}`);
  if (dialogElement) {
    dialogElement.hide();
  }
}
</script>
