module ImageDimensions
  def set_dimensions
    return unless image_file_path
    width, height = MiniMagick::Image.open(
      image_file_path.gsub(/\s/, '%20')
    ).dimensions
    update_column(:width, width.to_i) if width.to_i.positive?
    update_column(:height, height.to_i) if height.to_i.positive?
  end
  private :set_dimensions

  def image_file_path
    raise NotImplementedError
  end
  private :image_file_path
end
