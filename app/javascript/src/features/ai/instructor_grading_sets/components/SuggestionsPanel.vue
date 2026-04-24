<template>
  <div class="suggestions-panel">
    <div class="suggestions-header">
      <h3 class="header-text">
        <slot name="header-text" />
      </h3>
      <div class="header-controls">
        <slot name="header-controls" />
      </div>
    </div>
    <div class="suggestions">
      <slot name="suggestions" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
  .suggestions-panel {
    padding-bottom: 1rem;
  }

  .suggestions-header {
    align-items: center;
    display: flex;
    flex-direction: row;
    justify-content: space-between;
    margin-bottom: 1rem;
  }

  .header-text {
    display: inline-block;
    flex-grow: 1;
    font-family: 'Open Sans', sans-serif;
    font-weight: 600;
    margin-bottom: 0;
  }

  .header-controls {
    display: inline-block;
  }

  .suggestions {
    display: grid;
    font-family: 'Open Sans', sans-serif;
    gap: 0.62rem 1.31rem;
    grid-template-columns: 1fr 1fr;
  }
</style>
