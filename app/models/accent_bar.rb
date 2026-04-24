# encoding: utf-8
class AccentBar
  def self.characters(language)
    self.send(language.to_sym)
  end

  private

  # languages

  def self.es
    %w(
      á Á
      é É
      í Í
      ñ Ñ
      ó Ó
      ú Ú
      ü Ü
      ¿ ¿
      ¡ ¡
    ).each_slice(2).to_a
  end

  def self.fr
    %w(
      à À
      â Â
      ç Ç
      è È
      é É
      ê Ê
      ë Ë
      î Î
      ï Ï
      ô Ô
      œ Œ
      ù Ù
      û Û
      ü Ü
    ).each_slice(2).to_a
  end

  def self.it
    %w(
      à À
      è È
      é É
      ì Ì
      ò Ò
      ó Ó
      ù Ù
    ).each_slice(2).to_a
  end

  def self.de
    %w(
      ä Ä
      ö Ö
      ü Ü
      ß
    ).each_slice(2).to_a
  end

  def self.en
    []
  end

  def self.zh
    []
  end

  def self.ru
    []
  end
end
