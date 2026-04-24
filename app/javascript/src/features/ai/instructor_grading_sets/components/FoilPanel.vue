<template>
  <div class="foil-panel">
    <slot></slot>
  </div>
</template>

<style lang="scss" scoped>
  $_fallback-gradient: radial-gradient(circle at 80% -50%, #f8c7b9, #fcdfcd, #faffe5, #e1f6ef);

  .foil-panel {
    background: var(--ai-grading-gradient, $_fallback-gradient);
    border-radius: 0.5rem;
    padding: 1rem;
  }
</style>
