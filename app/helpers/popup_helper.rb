module PopupHelper

  def format_popup_onclick(popup_options = {})
    options = { :window_name => "popup_#{random_string(6)}",
                :directories => 'no',
                :location    => 'no',
                :menubar     => 'no',
                :resizable   => 'yes',
                :scrollbars  => 'yes',
                :status      => 'yes',
                :toolbar     => 'no',
                :href        => 'this.href'
              }.merge(popup_options)

    window_name = options.delete(:window_name)
    href = options.delete(:href)
    options_string = options.collect{|key, value| "#{key}=#{value}"}.sort.join(',')

    window_opening_code = "var w=window.open(#{href},"\
      "'#{window_name.gsub("'", %q(\\\'))}','#{options_string}'); w.focus();"
    # disable onclick when link has attribute "disabled".
    "if( !this.hasAttribute('disabled') ){ #{window_opening_code} }; return false;".html_safe
  end

  def random_string(length=13)
    chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789'
    uniqid = ''
    length.times { uniqid << chars[rand(chars.size)] }
    uniqid
  end
end
