#  encoding: utf-8

module FileTypeParsable
  def file_type(extension)
    case extension.downcase
      when '.pdf' then 'PDF'
      when '.doc', '.rtf', '.docx' then 'Document'
      when '.jpg', '.gif', '.png', '.jpeg' then 'Image'
      when '.ppt', '.pptx' then 'Presentation'
      when '.mp3', '.mp4' then 'Audio'
      when '.xls', '.xlsx' then 'Spreadsheet'
      else 'Other'
    end
  end
end
