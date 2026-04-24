<template>
  <ul class="tabs">
    <li
      v-for="tab in editTabs"
      :key="tab.id"
      class="tab"
      :class="[
        { 'current': tab.id === $route.name },
        testClass('edit-course-tab') ]">
      <a
        href="javascript://"
        class="link"
        :class="[
          { 'link--current': tab.id === $route.name },
          testClass('tab-link'),
        ]"
        @click="$router.push({ name: tab.id })">
        {{ tab.title }}
      </a>
    </li>
  </ul>
</template>

<script setup>
  import { testClass } from 'music';

  const editTabs = [
    { id: 'advanced-course-step', title: 'Course' },
    { id: 'content-step', title: 'Content' },
    { id: 'gradebook-step', title: 'Gradebook' },
    { id: 'summary-step', title: 'Summary' },
  ];
</script>

<style lang="scss" scoped>
  @use 'sass:math';
  @use '~MusicAssets/stylesheets/music/library/v1/base/main' as music;

  .tabs {
    display: flex;
    flex-wrap: wrap;
    list-style-type: none;
    flex-direction: row;
    flex-wrap: wrap;
    list-style-type: none;
    position: relative;
    top: -0.3rem;
  }

  .link {
    padding: 0 1rem 1rem 1rem;
    display: inline-block;
    color: music.$black;

    &--current {
      color: music.$black;
      font-weight: bold;
    }

    &:hover,
    &:focus {
      text-decoration: none;
      color: music.$black;
    }

    &:hover::after,
    &:focus::after,
    &--current::after {
      $width-offset: 0.8rem;

      background-color: music.$current;
      content: ' ';
      display: block;
      height: 0.3rem;
      left: math.div($width-offset, -2);
      position: relative;
      top: 0.4rem;
      width: calc(100% + $width-offset);
    }
  }
</style>
