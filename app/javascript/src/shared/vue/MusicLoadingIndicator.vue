<template>
  <svg
    title="Working."
    version="1.1"
    xmlns="http://www.w3.org/2000/svg"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    viewBox="0 0 64 64">
    <circle
      fill="inherit"
      stroke="none"
      cx="12"
      cy="32"
      r="6">
      <animate
        attributeName="opacity"
        dur="1.3s"
        values="0;1;0"
        repeatCount="indefinite"
        begin="0" />
      <animate
        attributeName="r"
        dur="1.3s"
        values="1;7;1"
        repeatCount="indefinite"
        begin="0" />
    </circle>
    <circle
      fill="inherit"
      stroke="none"
      cx="32"
      cy="32"
      r="6">
      <animate
        attributeName="opacity"
        dur="1.3s"
        values="0;1;0"
        repeatCount="indefinite"
        begin="0.33" />
      <animate
        attributeName="r"
        dur="1.3s"
        values="1;7;1"
        repeatCount="indefinite"
        begin="0.33" />
    </circle>
    <circle
      fill="inherit"
      stroke="none"
      cx="52"
      cy="32"
      r="6">
      <animate
        attributeName="opacity"
        dur="1.3s"
        values="0;1;0"
        repeatCount="indefinite"
        begin="0.66" />
      <animate
        attributeName="r"
        dur="1.3s"
        values="1;7;1"
        repeatCount="indefinite"
        begin="0.66" />
    </circle>
  </svg>
</template>

<script>
  const ALLOWED_VARIANTS = ['ellipsis'];

  export default {
    name: 'MusicLoadingIndicator',
    props: {
      classes: {
        type: Array,
        default: [],
      },
      variant: {
        type: String,
        default: 'ellipsis',
        validator: (value) => {
          return ALLOWED_VARIANTS.includes(value);
        },
      },
    },
  };
</script>
