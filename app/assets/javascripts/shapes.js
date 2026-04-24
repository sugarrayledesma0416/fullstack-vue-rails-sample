var VHL = VHL || {};

VHL.Shapes = (function () {
  /**
   *
   * TODO: this would be better as an instantiable class. --mh
   * 
   * 
   * Parameters for drawing shapes:
   *
   * density:         devicePixelRatio for the generated image.
   * borderWidth:    Thickness of pen stroke in CSS pixels. Applies only to 
   *                  outlined shapes.
   * backgroundColor:       The background color of the shape.
   * borderColor:     The outline color of the shape.
   * pointerWidth:    The horizontal length of the "arrow."
   */
  
  
  /* Defaults */
  var density = window.devicePixelRatio || 1,
      pointerWidth = 15;

  
  /**
   * Stretch the element to its parent.
   * 
   * @param {DOM reference} elem A reference to the shape element.
   */
  function stretchElement(elem) {
    var parent = elem.parentNode;
    elem.style.height = getElementSize(parent).height + 'px';
  }

  /**
   * Checks the size of the parent element.
   * 
   * @param {DOM reference} elem A reference to the parent element.
   * @return {object} An object containing the unitless width and
   *                  height of the parent.
   */
  
  function getElementSize(elem) {
    return {
      width: parseInt($(elem).outerWidth(),10),
      height: parseInt($(elem).outerHeight(),10)
    };
  }

  /**
   * Creates a new HTML5 Canvas element, sized to the full width & height of
   * the parent element. The actual pixel dimensions of the canvas takes into
   * account the current devicePixelRatio (pixel density), while the CSS width
   * & height determine the rendered size of the canvas.
   * 
   * @param {number} cssWidth The width of the element as specified in CSS. 
   * @param {number} cssHeight The height of the element as specified in CSS.
   * @return {DOM object} The canvas as a document fragment.
   */
  function makeCanvas(cssWidth, cssHeight) {
    var canvas = document.createElement('canvas');
    canvas.width = cssWidth * density;
    canvas.height = cssHeight * density;
    canvas.style.width = cssWidth + 'px';
    canvas.style.height = cssHeight + 'px'
    return canvas;
  }

  /**
   * Inserts the canvas into the parent node.
   * First it removes any canvasses already there, in case this is a refresh
   * due to the window being resized.
   * 
   * @param {DOM object} parentNode A reference to the parent element.
   * @param {DOM object} canvas A reference to the document fragment that is the
   * canvas element.
   */
  function mountCanvas(parentNode, canvas) {
    $(parentNode).find('canvas').remove();
    parentNode.appendChild(canvas);
  }

  /**
   * Renders the custom background shape to the canvas.
   *
   * @param {DOM object} parentNode The element in which the canvas is inserted.
   * @param {number} pointerWidth The width of the pointer "arrow", in CSS pixels.
   * @param {boolean} outline Indicates whether to draw a stroke on the shape.
   */
  function drawPointer(elem, pType, backgroundColor, borderColor, borderWidth) {
    var elementSize = getElementSize(elem),
        cssWidth = elementSize.width,
        cssHeight = elementSize.height,
        pixelWidth = cssWidth,
        pixelHeight = cssHeight,
        canvas = makeCanvas(cssWidth, cssHeight);
    
    mountCanvas(elem, canvas);
    if (canvas.getContext) {
      var ctx = canvas.getContext('2d');
      ctx.scale(density,density);
      if (pType === 'start') {
        drawStart(); 
      } else if (pType === 'end') {
        drawWhole(false);
      } else if (pType === 'whole') {
        drawWhole(true);
      }
    }


    function drawStart() {
      ctx.lineWidth = borderWidth;
      ctx.strokeStyle = borderColor;
      ctx.fillStyle = backgroundColor;
      ctx.beginPath();
      ctx.moveTo(cssWidth, 0);
      ctx.lineTo(0, 0);
      ctx.lineTo(0, cssHeight);
      ctx.lineTo(cssWidth, cssHeight);
      ctx.fill();
      ctx.stroke();
    }
    
    function drawWhole(isClosed) {
      /**
       * Fills in the pointer shape.
       */
      
      ctx.beginPath();
      ctx.fillStyle = backgroundColor;
      ctx.moveTo(0, 0);
      ctx.lineTo(cssWidth - pointerWidth, 0);
      ctx.lineTo(cssWidth, cssHeight / 2);
      ctx.lineTo(cssWidth - pointerWidth, cssHeight);
      ctx.lineTo(0, cssHeight);
      ctx.lineTo(0, 0);
      ctx.fill();

      /**
       * Draws the pointer shape outline.
       * Done in three segments se we can adjust the line weight 
       * so it is consistent at different angles.
       */
      
      ctx.beginPath();
      ctx.strokeStyle = borderColor;
      ctx.lineWidth = borderWidth;
      ctx.moveTo(0, 0);
      ctx.lineTo(cssWidth - pointerWidth, 0);      
      ctx.stroke();
      
      ctx.beginPath();
      ctx.moveTo(cssWidth - pointerWidth, 0);
      ctx.lineTo(cssWidth - borderWidth / 2, cssHeight / 2);
      ctx.lineTo(cssWidth - pointerWidth, cssHeight);
      
      ctx.lineWidth = borderWidth * 0.5;
      ctx.stroke();
      
      ctx.beginPath();
      ctx.moveTo(cssWidth - pointerWidth, cssHeight);
      ctx.lineTo(0, cssHeight);
      
      // close the shape?
      if (isClosed) {
        ctx.lineTo(0,0);
      }

      ctx.lineWidth = borderWidth;
      ctx.stroke();
    }
  }

  function removeSavedStyles(elem) {
    elem.removeAttribute('data-background-color');
    elem.removeAttribute('data-border-color');
    elem.removeAttribute('data-border-width');
    elem.removeAttribute('style');
  }

  /**
   * Move CSS styles to element data attributes.
   */
  function saveStyles() {
    $('.js-pointer').each(function(index, elem) {
      removeSavedStyles(elem);
      // Using border-top-* instead of border-* b/c some browsers don't return
      // a value for border, only the separate sides. This works b/c in this
      // case all the sides are always equal.
      elem.setAttribute('data-background-color', getStyle(elem, 'background-color'));
      elem.setAttribute('data-border-color', getStyle(elem, 'border-top-color'));
      elem.setAttribute('data-border-width', getStyle(elem, 'border-top-width'));
      clearStyles(elem);
    });
  }

  function getStyle(elem, prop) {
    return window.getComputedStyle(elem).getPropertyValue(prop);
  }

  
  /**
   * Hide original element styles.
   */
  function clearStyles(elem) {
    elem.style.backgroundColor = 'transparent';
    elem.style.borderColor = 'transparent';
    elem.style.borderWidth = '0';
    // preserve element size
    elem.style.height = getElementSize(elem).height + 'px';
  }

  
  /**
   * For all elements with class .js-pointer, add the pointer shape.
   */
  function setupPointers() {
    pointerStart = false;
    pointerEnd = false;
    $('.js-pointer').each(function(index,elem) {
      stretchElement(elem);
      var backgroundColor = elem.getAttribute('data-background-color');
      var borderColor = elem.getAttribute('data-border-color');
      var borderWidth = parseInt(elem.getAttribute('data-border-width'), 10);
      drawPointer(elem, pointerType(elem), backgroundColor, borderColor, borderWidth);
    });
  }

  function pointerType(elem) {
    return elem.getAttribute('data-pointer');
  }

  function refresh() {
    saveStyles();
    setupPointers();
  }

  /**
   * Draw the pointers, and set up a handler to re-draw them when the window
   * is resized.
   */
  function init() {
    $(window).on('resize', setupPointers);
    refresh();
  }

  return {
    init: init,
    refresh: refresh,
  };
})();

/*
    Module should be initialized by the code that uses it,
    via VHL.Shapes.init();

 */
