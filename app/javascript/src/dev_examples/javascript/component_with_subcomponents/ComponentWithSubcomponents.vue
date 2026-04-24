<template>
"In this box are two things/ I will show to you now./ You will like these two things,"/ Said the cat with a bow.
<Thing thing-number="One"></Thing>
<Thing thing-number="Two"></Thing>
</template>

<script>
import Thing from './Thing';

export default {
  name: 'ComponentMountedOnElement',
  components: {
    Thing
  }
};
</script>
