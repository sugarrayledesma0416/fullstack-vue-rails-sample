class FileUploadUrl
  attr_accessor :relative_url

  def initialize(relative_url:)
    self.relative_url = relative_url
    @signer = Aws::CloudFront::UrlSigner.new(
      key_pair_id: ENV['CLOUDFRONT_SIGNER_KEY_ID'],
      private_key: ENV['CLOUDFRONT_SIGNER_KEY']
    )
  end

  def full_url
    "https://#{Radner.bucket_name}/#{relative_url}"
  end

  def signed_url
    @signer.signed_url(full_url, expires: 10.minutes.from_now)
  end
end
