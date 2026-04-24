window.addEventListener('DOMContentLoaded', () => {
  const programSelect = document.getElementById('program_id');
  const exportButton = document.getElementById('export_button');
  const csvButton = document.getElementById('csv_button');
  const csvProgramIdInput = document.getElementById('csv_program_id');

  if (exportButton) {
    exportButton.disabled = true;
  }
  if (csvButton) {
    csvButton.disabled = true;
  }

  if (programSelect) {
    programSelect.addEventListener('change', () => {
      const selectedValue = programSelect.value;
      const isProgramSelected = selectedValue !== '';

      if (exportButton) {
        exportButton.disabled = !isProgramSelected;
      }
      if (csvButton) {
        csvButton.disabled = !isProgramSelected;
      }
      if (csvProgramIdInput) {
        csvProgramIdInput.value = selectedValue;
      }
    });
  }
});
