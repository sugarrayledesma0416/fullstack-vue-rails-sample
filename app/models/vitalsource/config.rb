module Vitalsource
  class Config
    attr_writer :api_url, :api_key, :bookshelf_url

    ## Valid book_ids to use in the sandbox:
    # BOOKSHELF-TUTORIAL
    # 1-889325-26-0
    # L-999-70103

    def api_url
      valid(@api_url) || raise_missing('api_url')
    end

    def api_key
      valid(@api_key) || raise_missing('api_key')
    end

    def bookshelf_url
      valid(@bookshelf_url) || raise_missing('bookshelf_url')
    end

    private def raise_missing(key)
      raise("Vitalsource config variable #{key} is blank.")
    end

    private def valid(orig_value)
      # Weed out blank and white-space only values as well as nils.
      value = orig_value.to_s.strip
      value.present? && value
    end
  end
end
