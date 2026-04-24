<template>
  <svg class="icon" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 20 20">
    <g>
      <path d="M0.75,9.00684547 L0.75,16.9941413 C0.75,17.6892273 1.30795285,18.25 1.99508929,18.25 L18.0049107,18.25 C18.6920111,18.25 19.25,17.6888808 19.25,16.9941413 L19.25,9.00684547 L0.99339768,9.00684547 L0.75,9.00684547 Z" />
      <g transform="matrix(1 0 0 -1 0 9)">
        <path d="M2.6,7 L17.4,7 L18.0049107,7 C18.5537356,7 19,6.55145069 19,5.9951185 L19,2 L1,2 L1,5.9951185 C1,6.55333959 1.44504866,7 1.99508929,7 L2.6,7 Z" />
      </g>
      <rect width="2" height="4" x="4.5" y=".5" rx="1" />
      <rect width="2" height="4" x="13.5" y=".5" rx="1" />
    </g>
  </svg>
</template>
<style scoped lang="sass">
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .icon {
    display: inline-block;
    text-decoration: none;
    white-space: nowrap;
    width: 1rem;
    height: 1rem;
    line-height: 1rem;
    background-size: 1rem 1rem;
  }

  .icon.calendar-icon--disabled[tabindex="-1"]:focus {
    outline-color: transparent;
  }

  .icon.calendar-icon--disabled * {
    fill: $gray-c;
  }

  .icon:not(.calendar-icon--disabled) {
    & * {
      fill: $base-blue;
    }

    &:hover *, &:focus * {
      fill: $dark-blue;
    }
  }
</style>
