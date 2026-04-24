<template>
<div class="thing">
  Thing {{ thingNumber }}
</div>
</template>

<script>
export default {
  name: 'Thing',
  props: {
    thingNumber: String
  }
};
</script>

<style>
.thing {
  border: 1px black solid;
  background-color: lightblue;
  text-align: center;
  width: 10%;
  padding: 5px;
  margin: 5px;
}
</style>
