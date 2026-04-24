class ForumPost < ApplicationRecord
  belongs_to :forum
  belongs_to :user

  validates :text, presence: { message: 'or an audio recording is required',
                               unless: ->(post) { post.audio_path.present? } }
  validates :audio_path, presence: { message: 'or text is required',
                                     unless: ->(post) { post.text.present? } }

  def audio_uri
    audio_path.present? && cdn_prefix + audio_path
  end

  def cdn_prefix
    M3::Application.config.multimedia.forums.cdn_prefix
  end

  def edited?
    edited_at.present?
  end

  def delete!
    self.deleted = true
    self.text = 'Deleted post'
    self.save!
  end
end
