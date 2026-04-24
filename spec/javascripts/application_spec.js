describe('VHL.Common', function() {
  describe('#unescape_xml_entities', function() {
    it('decodes xml entities for \& \' \" \> \<', function() {
      var test = "&lt; &amp; I said &quot;Hey yay&quot; What&apos;s goin&apos; on? &gt;";
      test = VHL.Common.unescape_xml_entities(test);
      expect(test).toBe("< & I said \"Hey yay\" What's goin' on? >");
    });
  });
});
