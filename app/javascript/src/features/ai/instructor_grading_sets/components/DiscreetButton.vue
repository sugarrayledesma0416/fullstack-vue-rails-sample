<template>
  <div>
    <button class="discrete-button">
      <slot />
    </button>
  </div>
</template>

<style lang="scss" scoped>
  .discrete-button {
    align-items: center;
    background: transparent;
    border: none;
    border-radius: 100%;
    cursor: pointer;
    display: inline-flex;
    justify-content: center;
    padding: 0.5rem;

    &:hover, &:focus {
      background-color: rgba(255, 255, 255, 0.9);
      box-shadow: 0 0.25rem 0.25rem 0 rgba(0, 0, 0, 0.15);
    }
  }
</style>
