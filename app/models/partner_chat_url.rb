class PartnerChatUrl
  attr_accessor :relative_url

  def initialize(relative_url:)
    self.relative_url = relative_url
    @signer = Aws::CloudFront::UrlSigner.new(key_pair_id: ENV['CLOUDFRONT_SIGNER_KEY_ID'],
                                             private_key: ENV['CLOUDFRONT_SIGNER_KEY'])
  end

  def full_url
    "#{Rails.configuration.partner_chat_cdn}/#{relative_url}"
  end

  def signed_url
    @signer.signed_url(full_url, policy: policy.to_json)
  end

  # Custom policy for Cloudfront distribution.
  # We expect to only have access for 10 minutes from `now`.
  # This policy structure is following the one represented in the AWS docs about signed cookies and policies.
  # https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-setting-signed-cookie-custom-policy.html#private-content-custom-policy-statement-cookies-values
  private def policy
    {
      'Statement' => [{ 'Resource' => "#{full_url}", 'Condition' => {
        'DateLessThan' => { 'AWS:EpochTime' => (Time.zone.now + 10.minutes).to_i }
      }}]
    }
  end
end
