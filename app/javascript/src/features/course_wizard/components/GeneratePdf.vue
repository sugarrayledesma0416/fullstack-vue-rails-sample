<template>
  <div class="generate-pdf-container">
    <form
      id="generatePdfForm"
      ref="generatePdfForm"
      :class="testClass('generate-pdf-form')"
      method="post"
      :action="formUrl">
      <input type="hidden" name="authenticity_token" :value="authenticityToken">
      <input type="hidden" name="course_data" :value="courseData">
      <input type="hidden" name="course_packages_names" :value="coursePackageNames">
    </form>

    <VhlLink
      href="javascript://"
      testSelector="generate-pdf"
      variant="button"
      featureVariant="learning-tracks"
      @click="generatePdf()">
      Generate PDF
    </VhlLink>
  </div>
</template>

<script>
  import { inject, ref } from 'vue';
  import { metaTagContent } from 'shared/utils';
  import { testClass } from 'music';
  import VhlLink from './VhlLink';

  export default {
    name: 'GeneratePdf',
    components: { VhlLink },
    setup() {
      const authenticityToken = metaTagContent('csrf-token');
      const config = inject('config');
      const courseDataStore = inject('courseDataStore');
      const coursePackages = courseDataStore.courseSerializer.coursePackagesNames(
        courseDataStore.store.courseOptions.levels,
        courseDataStore.store.courseOptions.components
      );
      const course = courseDataStore.store.course;
      const courseData = encodeURIComponent(
        JSON.stringify(courseDataStore.courseSerializer.serialize(course))
      );
      const coursePackageNames = encodeURIComponent(JSON.stringify(coursePackages));
      const generatePdfForm = ref(null);
      const formUrl = `/instructor/${config.programId}/courses/show_summary_pdf.pdf`;

      /**
       * sends request to generate course summary pdf.
       */
      function generatePdf() {
        courseDataStore.store.generatingPdf = true;
        generatePdfForm.value.submit();
      }

      return {
        authenticityToken,
        courseData,
        coursePackageNames,
        formUrl,
        generatePdf,
        generatePdfForm,
        testClass,
      };
    },
  };
</script>

<style scoped>
 .generate-pdf-container {
    text-align: right;
  }
</style>
