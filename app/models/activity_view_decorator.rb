module ActivityViewDecorator
  attr_accessor :vtext_linker

  def populate_vocab_groups
    content_object.groups.each do |group|
      next if group.id.blank?

      group_media = MediaItem.find(group.id)
      group.base_dir = group_media.base_dir
      group.public_dir = group_media.unzipped_directory
      group.content_csv = group_media.csv_content
      group.populate_content_from_csv
    end
  end

  def populate_activity_media
    case content_object.activity_type
    when 'vocab_list'
      populate_vocab_groups
    when 'tutorial_vocab', 'tutorial_vocab_html5'
      content_object.populate_dirs_from_media
    when 'game'
      content_object.ensure_public_media_files
    end
  end

  def randomize(number)
    content_object.activity_order_seed = number
  end

  def initialize_vtext_linker(program, presenter, session)
    @vtext_linker = VtextLinker.new(program, presenter, self, session:)
    self.vtext_link = @vtext_linker
  end
end
