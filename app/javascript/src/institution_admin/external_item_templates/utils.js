const setDatepickerDate = (selector, date) => {
  let $datepicker = $(selector);
  $datepicker.datepicker('option',
    { minDate: $datepicker.data('min'),
      maxDate: $datepicker.data('max') }
  );

  if (date === undefined) {
    date = $datepicker.data('date');
  }

  $datepicker.datepicker('setDate', new Date(date));
};

const observeAttrChange = (target, attrName, dispatchTarget) => {
  const config =  { attributes: true };
  const callback = (mutationsList, observer) => {
    for (let mutation of mutationsList) {
      if (mutation.attributeName === attrName) {
        dispatchTarget.dispatchEvent(new Event('change'));
      }
    }
  };

  const observer = new MutationObserver(callback);
  observer.observe(target, config);
};

const optionIndexLookup = (elm) => {
  return [...elm.querySelectorAll('option')].reduce(
    (acc, curr, idx) => {
      acc[curr.value] = idx;
      return acc;
    },
    {}
  );
}

export { observeAttrChange, optionIndexLookup, setDatepickerDate };
