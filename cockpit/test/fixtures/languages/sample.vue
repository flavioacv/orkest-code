<!-- Vue 3 sample fixture -->
<script setup lang="ts">
import { ref } from 'vue';

const count = ref(0);
function increment() {
  count.value++;
}
</script>

<template>
  <button @click="increment">Count: {{ count }}</button>
</template>
