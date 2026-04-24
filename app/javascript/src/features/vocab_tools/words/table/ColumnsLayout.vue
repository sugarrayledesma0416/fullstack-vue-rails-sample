<template>
  <!--
    This components sets fixed % width for table columns so that
    column widths are in sync across tables.
  -->
  <col
    v-for="columnNumber in totalColumns"
    :key="columnNumber"
    :class="{
      'c-vocab-tools-3-cols': totalColumns === 3,
      'c-vocab-tools-4-cols': totalColumns === 4,
      'c-action-col': columnNumber === totalColumns,
    }">
</template>

<script>
  export default {
    name: 'ColumnsLayout',
    props: {
      totalColumns: { default: 3, type: Number },
    },
  };
</script>
<style lang="sass" scoped>
  /*
    Logic For Width: ~20% width is set for the last column (column with actions buttons)
      and rest of the width is divided equally.
  */
  .c-vocab-tools-3-cols {
    width: 40%;
  }

  .c-vocab-tools-3-cols.c-action-col {
    width: 20%;
  }

  .c-vocab-tools-4-cols {
    width: 26%;
  }

  .c-vocab-tools-4-cols.c-action-col {
    width: 22%;
  }
</style>
