module PortfolioHelper
  def embed_remote_image(url)
    file_extension = File.extname(url).delete_prefix('.')
    content_type = content_type_from_extension(file_extension)
    asset = URI.parse(url).open(encoding: 'UTF-8').read
    base_64 = Base64.encode64(asset.to_s).gsub(/\s+/, '')
    "data:#{content_type};base64,#{Rack::Utils.escape(base_64)}"
  end

  private def content_type_from_extension(file_extension)
    case file_extension.downcase
    when 'jpg', 'jpeg'
      'image/jpeg'
    when 'gif'
      'image/gif'
    when 'svg'
      'image/svg+xml'
    else
      'image/png'
    end
  end

  def format_portfolio_program_logo(program)
    options = { class: 'program-logo' }
    if program&.logo_media
      options[:alt] = program.title
      options[:width] = 'auto'
      options[:height] = '60px'
      options[:reference_in_artifact] = true
      display_media_item(program.logo_media, options)
    else
      content_tag(:a, id: 'vista_logo', name: 'vista_logo') do
        image_tag(embed_remote_image('vista_logo.png'), alt: 'Vista Higher Learning')
      end
    end
  end

  def program_logo_svg?(program)
    filename = program&.logo_media&.public_filename || ''
    File.extname(filename).delete_prefix('.').downcase == 'svg'
  end
end
