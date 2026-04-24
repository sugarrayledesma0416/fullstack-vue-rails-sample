<template>
  <li>
    <a
      :href="href"
      :class="[
        itemClass,
        'action-menu__item'
      ]"
      :target="target">
      <slot />
    </a>
  </li>
</template>

<script>
  export default {
    name: 'ActionMenuItem',
    props: {
      href: { default: 'javascript://', type: String },
      itemClass: { default: '', type: String },
      target: { default: '', type: String },
    },
  };
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .action-menu {
    &__item {
      display: block;
      padding: ($padding-lg * 0.5) $padding-lg;

      &[href] {
        transition: $fade-fast;
      }
    }
  }
</style>
