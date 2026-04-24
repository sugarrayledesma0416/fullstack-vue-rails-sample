describe Etl::GradebookImport::StringSanitizer do
  describe '#sanitize' do
    it 'strips line breaks from a string' do
      new_str = TestBase.new.sanitize('Strukturen 3A.2<br />Descriptive adjectives and adjective agreement')
      expect(new_str).to eql('Strukturen 3A.2 Descriptive adjectives and adjective agreement')
      new_str = TestBase.new.sanitize('<br>Strukturen 3A.2<br/> Descriptive adjectives and adjective agreement')
      expect(new_str).to eql('Strukturen 3A.2 Descriptive adjectives and adjective agreement')
    end

    it 'strips HTML tags from a string' do
      new_str = TestBase.new.sanitize('4.4 To become: <b>hacerse, ponerse, volverse</b>, and <b>llegar a ser</b>')
      expect(new_str).to eql('4.4 To become: hacerse, ponerse, volverse, and llegar a ser')
    end

    it 'strips both line breaks and HTML tags from a string' do
      new_str = TestBase.new.sanitize('<b>Strukturen 12A.1</b> <i>Der Konjunktiv der Vergangenheit</i>')
      expect(new_str).to eql('Strukturen 12A.1 Der Konjunktiv der Vergangenheit')
    end
  end

  class TestBase
    include Etl::GradebookImport::StringSanitizer
  end
end
