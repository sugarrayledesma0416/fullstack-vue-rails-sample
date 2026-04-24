<template>
  <div class="action-menu__wrapper  js-action-menu">
    <button
      class="action-menu__title"
      :class="[
        titleClass,
        {'js-action-menu__button': isActive }
      ]">
      <slot name="title" />
    </button>

    <ul
      v-if="isActive"
      class="action-menu__inner  js-action-menu__list  u-hidden">
      <slot name="items" />
    </ul>
  </div>
</template>

<script>
  export default {
    name: 'ActionMenu',
    props: {
      titleClass: { default: '', type: String },
      isActive: { required: true, type: Boolean },
    },
  };
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .action-menu {
    &__wrapper {
      display: inline-block;
      height: 100%;
      width: 100%;
    }

    &__title {
      display: block;
      cursor: pointer;
      transition: color 0.2s ease-in-out, box-shadow 02s ease-in-out;

      &:hover {
        color: $link-hover-color;
        text-decoration: underline;
      }
    }

    &__inner {
      position: absolute;
      left: inherit;
      z-index: z(menu);
      padding: 0.5rem;
      min-width: 10em;
      max-width: 20em;
      overflow-x: hidden;
      background-color: $white;
      box-shadow: $box-shadow-3;
      transition: $fade-fast;
      white-space: nowrap;
    }
  }
</style>
