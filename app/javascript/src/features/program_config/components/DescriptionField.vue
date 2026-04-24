<template>
  <div>
    <textarea
      :id="`description-${type}`"
      v-model="description.value"
      v-ckeditor="ckeditorOptions"
      :class="testClass(`description-${type}`)" />
    <input
      :id="id"
      :class="testClass(`desciption-input-${type}`)"
      type="hidden"
      :name="name"
      :value="description.value">
  </div>
</template>

<script>
  import { testClass } from 'music';
  import ckeditor from 'shared/directives/ckeditor';
  import { reactive } from 'vue';

  export default {
    name: 'DescriptionField',
    directives: { ckeditor },
    props: {
      id: { required: true, type: String },
      name: { required: true, type: String },
      type: { required: true, type: String },
      value: { required: true, type: String },
    },
    setup(props) {
      const description = reactive({ value: props.value });
      const ckeditorOptions = {
        toolbar: [
          { name: 'basicstyles', items: ['Bold', 'Italic', 'Underline'] },
          { name: 'paragraph',
            items: [
              'NumberedList',
              'BulletedList',
            ],
          },
          '/',
          { name: 'styles', items: ['Font', 'FontSize'] },
          { name: 'colors', items: ['TextColor', 'BGColor'] },
        ],
        removePlugins: 'elementspath',
        removeButtons: 'Subscript,Superscript',
        uiColor: '#E5E5E5',
        height: '100px',
      };
      return { ckeditorOptions, description, testClass };
    },
  };
</script>
