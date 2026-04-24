WICKED_PDF = {}

wkhtmltopdf_config_path = "config/wkhtmltopdf_path.txt"
if File.exist?(wkhtmltopdf_config_path)
  wkhtmltopdf_path = File.read(wkhtmltopdf_config_path).strip
  WICKED_PDF[:wkhtmltopdf] = wkhtmltopdf_path
end
