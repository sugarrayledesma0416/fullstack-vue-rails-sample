(function($){

    $.fn.identify = function(options) {
        var opts = $.extend(true,{}, $.fn.identify.defaults, options);

        return this.each(function() {
                $this = $(this);
                var o = ($.meta ? $.extend(true,{},opts,$this.data) : opts);

                var id=$this.attr('id');

                if(id){
                    if(o.unique == false || $('[id='+id+']').length<=1){
                        return;
                    }
                }

                do {
                    id = o.prefix + o.separator + o.guid(o.guidSeparator);
                } while($('#' + id).length > 0);

                $this.attr('id', id);
            });
    };

    /**
     *  @description Object of identify plugin options
     **/
    $.fn.identify.defaults = {
         prefix : 'id'  // prefix used for the generated id
        /**
         * @description inspired from the exelent article http://note19.com/2007/05/27/javascript-guid-generator/
         * @param string sep, the separator use to return de generated guid (default = "-")
         */
        ,guid : function(sep){
              /**
               * @description Internal function that returns a hexadecimal number
               * @return an random hexa décimal value between 0000 and FFFF
               */
              function S4() {
               return (((1+Math.random())*0x10000)|0).toString(16).substring(1);
            }

            if(typeof sep == "undefined") sep ="-"

            return (S4()+S4()+sep+S4()+sep+S4()+sep+S4()+sep+S4()+S4()+S4());
        }
        ,unique : false             // If an id is found, test if it's unique or assign a new one
        ,separator : '_'            // Separator used between prefix and guid
        ,guidSeparator : '-'        // Separator unsed between guid's elements'

    }
})(jQuery);
