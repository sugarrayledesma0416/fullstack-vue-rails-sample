<template>
  <th
    class="c-col-head--gb  c-col-head--gb-strand"
    :colspan="strand.count"
    scope="col"
    :style="`border-top: thick solid ${strand.color};`"
    :title="strand.name">
    <span class="c-col-head-link--gb  c-col-head-link--gb-strand">
      {{ strand.name }}
    </span>
  </th>
</template>

<script>
  export default {
    name: 'StrandHeader',
    props: { strand: { required: true, type: Object }},
  };
</script>
