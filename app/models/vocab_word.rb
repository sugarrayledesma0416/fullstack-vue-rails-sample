class VocabWord < ApplicationRecord
  include RecordingPath
  attr_accessor :temp_file_path, :original_filename, :_destroy_image

  belongs_to :student, foreign_key: :user_id, class_name: 'User'
  belongs_to :recording, optional: true
  belongs_to :vocab_program_group, optional: true
  belongs_to :default_vocab_word, optional: true
  belongs_to :lesson

  has_many :vocab_tags, dependent: :destroy, inverse_of: :vocab_word
  accepts_nested_attributes_for :vocab_tags, allow_destroy: true

  validates_presence_of :user_id
  validates_presence_of :language

  validate :target_base_or_definition_required

  # temporarily disabled until the image uploading funcionality will be restored
  #
  # before_save :set_dimensions, if: :file_was_uploaded?
  # before_save :resize, if: :oversized_image?
  # after_save :update_image_filename, :store_file, if: :file_was_uploaded?
  # after_update :delete_file_and_update_record, if: :file_marked_for_destruction?
  # after_destroy :delete_file

  def target_base_or_definition_required
    if missing_base_target_or_definition?
      errors.add(:base, 'Target word, base word, or definition must be entered.')
    end
  end

  DEFAULT_VOCAB_WORD_SELECT = <<~SELECT_FIELDS.freeze
    default_vocab_words.id, NULL as user_id, NULL as default_vocab_word_id,
    lessons.name as lesson_name, default_vocab_words.lesson_id,
    default_vocab_words.target_word, default_vocab_words.base_word,
    default_vocab_words.target_definition, default_vocab_words.language,
    default_vocab_words.created_at, 0 as archived, 1 as default_vocab_word,
    default_vocab_words.vocab_program_group_id, default_vocab_words.program_id
  SELECT_FIELDS

  VOCAB_WORD_SELECT = <<~SELECT_FIELDS.freeze
    vocab_words.id, user_id, default_vocab_word_id, target_word, base_word,
    lessons.name as lesson_name, target_definition, language,
    vocab_words.created_at, archived, 0 as default_vocab_word, lesson_id,
    vocab_program_group_id, program_id, recording_id, image_filename
  SELECT_FIELDS

  # Ideally, this would be a union, except we need to eager load the vocab
  # tags. If a union were used, it wouldn't be possible to tell whether
  # records are default or non-default vocab words, which is necessary in
  # order to build the query to get the tags.
  def self.find_or_build_vocab_words(student, program)
    language = program.language_code

    # rubocop:disable Layout/MultilineMethodCallIndentation
    default_words = DefaultVocabWord.select(DEFAULT_VOCAB_WORD_SELECT)
      .left_outer_joins(:lesson)
      .joins(
        sanitize_sql_array(
          [
            'LEFT OUTER JOIN vocab_words ON default_vocab_words.id = ' \
            'vocab_words.default_vocab_word_id AND vocab_words.user_id = ?',
            student.id
          ]
        )
      )
      .where(
        default_vocab_words: { program_id: program.id },
        vocab_words: { id: nil }
      )
      .order('lessons.name, default_vocab_words.target_word')
      .includes(:vocab_tags)

    vocab_words = VocabWord.select(VOCAB_WORD_SELECT)
      .left_outer_joins(:lesson)
      .where(vocab_words: { archived: false, user_id: student.id })
      .where(
        '(default_vocab_word_id is null AND language = ?) OR program_id IN (?)',
        language, program.id
      )
      .order('lessons.name, vocab_words.target_word')
      .includes(:vocab_tags, :recording)
    # rubocop:enable Layout/MultilineMethodCallIndentation

    vocab_words + default_words
  end

  def self.available_lessons_for_user(user, program)
    Lesson.joins(:unit)
          .joins('INNER JOIN programs p ON p.id = units.program_id')
          .where('units.program_id IN (?)', program.id)
          .non_resource.select('p.title as program_name, lessons.id, lessons.label, lessons.name')
  end

  def as_json(options = {})
    super(options.merge({
      :methods => [:recording_path, :public_filename]
    }))
  end

  def self.serialize_to_json_for_student_and_language(student, program)
    activities = JSON.parse(find_or_build_vocab_words(student, program).to_json(:include => :vocab_tags))
    { 'language' => program.language_code,
      'activities' => activities,
      'lessons' => available_lessons_for_user(student, program) }.to_json
  end

  def missing_base_target_or_definition?
    base_word.blank? && target_word.blank? && target_definition.blank?
  end
  private :missing_base_target_or_definition?

  def file_was_uploaded?
    temp_file_path.present? && original_filename.present? && File.exist?(temp_file_path)
  end
  private :file_was_uploaded?

  def resize
    source_image.resize('540x340')
  end
  private :resize

  def oversized_image?
    file_was_uploaded? && (@width > 540 || @height > 340)
  end
  private :oversized_image?

  def set_dimensions
    @width, @height = source_image.dimensions
  end
  private :set_dimensions

  private def source_image
    @source_image ||= MiniMagick::Image.new(temp_file_path)
  end

  def id_string
    ("%08d" % user_id)
  end
  private :id_string

  def dir_chunk
    id_string[0..3]
  end
  private :dir_chunk

  def subdir_chunk
    id_string[4..8]
  end
  private :subdir_chunk

  def file_directory
    Rails.root.join('public', common_path)
  end
  private :file_directory

  def extname
    File.extname(original_filename).downcase
  end
  private :extname

  def filename
    "#{id}#{extname}"
  end
  private :filename

  def common_path
    File.join('student_vocab_media', Rails.env, 'images', dir_chunk, subdir_chunk)
  end
  private :common_path

  def public_filename
    File.join(common_path, image_filename) if image_filename.present?
  end

  # File final's destination
  def file_path
    File.join(file_directory, image_filename)
  end
  private :file_path

  def store_file
    FileUtils.mkdir_p(file_directory) unless File.directory?(file_directory)
    FileUtils.move(temp_file_path, file_path)
    FileUtils.chmod(0744, file_path) # Give user and group permissions to read the file.
  end
  private :store_file

  def update_image_filename
    update_column(:image_filename, filename)
  end
  private :update_image_filename

  def delete_file
    File.unlink(file_path) if image_filename.present? && File.exist?(file_path)
  end
  private :delete_file

  def delete_file_and_update_record
    delete_file
    update_column(:image_filename, nil)
  end

  def file_marked_for_destruction?
    _destroy_image == '1'
  end
  private :file_marked_for_destruction?
end
