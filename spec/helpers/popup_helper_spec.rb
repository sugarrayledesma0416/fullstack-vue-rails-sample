describe PopupHelper do
  include PopupHelper


  describe "#format_popup_onclick" do
    it "returns options for onclick with defaults" do
      matches = /\{ ([^']*)'([^']*)','([^']*)'(.*)/.match(format_popup_onclick)

      expect(matches[1]).to eql 'var w=window.open(this.href,'
      expect(matches[2]).to match(/popup_\w{6}/)
      expect(matches[3]).to eql 'directories=no,location=no,menubar=no,resizable=yes,scrollbars=yes,status=yes,toolbar=no'
      expect(matches[4]).to eql '); w.focus(); }; return false;'
    end

    it "returns options for onclick, overriding defaults with params" do
      options = { :window_name => "valid_window_name",
                  :height      => 40,
                  :width       => 184,
                  :location    => 'yes',
                  :menubar     => 'yes', }
      matches = /([^']*)'([^']*)','([^']*)'(.*)/.match( format_popup_onclick(options) )

      expect(matches[2]).to eql 'valid_window_name'
      expect(matches[3]).to eql 'directories=no,height=40,location=yes,menubar=yes,resizable=yes,scrollbars=yes,status=yes,toolbar=no,width=184'
    end

    it 'escapes the single quotes in the window name' do
      options = { window_name: "Palme D'or" }
      result = format_popup_onclick(options)
      expect(result).to include "window.open(this.href,'Palme D\\'or',"
    end
  end
end
