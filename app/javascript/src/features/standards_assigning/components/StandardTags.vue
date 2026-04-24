<template>
  <div
    class="cart-items"
    :class="testClass('cart-items')">
    <sl-tag
      v-for="(item, index) in store.convertStandardGuidToNumber(cartItems)"
      :key="index"
      :class="testClass('cart-item')"
      tabindex="0"
      size="medium"
      removable
      @sl-remove="removeItem(item.vendor_guid)"
      @keyup.enter="removeItem(item.vendor_guid)">
      <sl-tooltip
        :class="testClass('cart-item-tooltip')"
        :content="item.description"
        placement="top">
        <span
          :class="testClass('cart-item-text')"
          class="u-txt-16">
          {{ item.display_number }}
        </span>
      </sl-tooltip>
    </sl-tag>
  </div>
</template>

<script setup>
  import { testClass } from 'music';
  import useStandardsAssigningStore from './../models/use_standards_assigning_store.js';

  defineProps({
    cartItems: { required: true, type: Array },
  });
  const store = useStandardsAssigningStore();

  const emit = defineEmits(['removeItem']);

  /**
   * Emits removeItem event with the item to remove
   * @param {string} item - Cart item to remove
   */
  function removeItem(item) {
    emit('removeItem', item);
  }
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .cart-items {
    display: flex;
    flex-wrap: wrap;
    gap: rpx(8);
    margin-top: rpx(16);
    margin-bottom: rpx(48);
  }

  sl-tag::part(base) {
    background: #DBECF8;
    border: none;
    color: black;
    font-size: rpx(14);
    padding: rpx(5);
  }

  sl-tag::part(remove-button) {
    color: #006BAE;
  }
</style>
