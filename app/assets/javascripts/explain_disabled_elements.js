
$(document).ready(function() {
  prepare_disabled_element_explanations();
});

function prepare_disabled_element_explanations() {
  if($('.disabled_element_wrapper').length != 0){
    $('.disabled_element_wrapper').cluetip({ local:        true,
                                              attribute:    'rel',
                                              cluetipClass: 'hover-warning',
                                              activation:   'hover',
                                              width:         250,
                                              cluezIndex:    2001,
                                              showTitle:     false,
                                              mouseOutClose: true,
                                              onHide: function(){$('#cluetip-inner').empty();}  });
  }
}
