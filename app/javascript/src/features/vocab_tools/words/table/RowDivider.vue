<template>
  <tr class="c-row--divider" aria-hidden="true">
    <td :colspan="colspan" :class="testClass('td-divider')">
      <div class="c-row-divider" />
    </td>
  </tr>
</template>

<script>
  import { testClass } from 'music';

  export default {
    name: 'RowDivider',
    props: {
      colspan: { default: 1, type: Number },
    },
    setup(props) {
      return { testClass };
    },
  };
</script>
<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .c-row--divider {
    height: rpx(1);
  }

  .c-row--divider:last-child {
    display: none;
  }

  .c-row--divider td {
    padding: 0;
  }

  .c-row-divider {
    height: rpx(1);
    margin: 0 auto;
  }
</style>
