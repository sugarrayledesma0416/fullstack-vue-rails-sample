module S3AssetUploader
  def upload_to_s3(bucket:, assets:, asset_parent_dir:)
    assets.each do |asset|
      object = bucket.object("#{asset_parent_dir}/#{asset}")
      mime_type = MIME::Types.type_for(asset).first
      content_type = if mime_type
                       mime_type.content_type
                     else
                       puts "cannot determine content type of #{asset}"
                       'text/plain'
                     end
      if object.exists?
        puts("skipping #{asset} (#{content_type})")
      else
        puts("uploading #{asset} (#{content_type})")
        object.upload_file(
          "public/#{asset_parent_dir}/#{asset}",
          cache_control: 'max-age=31536000',
          content_type: content_type
        )
      end
    end
  end
  module_function :upload_to_s3
end

namespace :assets do
  desc 'Upload compiled assets to S3'
  task :upload do
    require 'mime-types'
    require 'aws-sdk-s3'
    require 'sprockets'

    env = ENV['RAILS_ENV'] || 'staging'
    bucket_name = {
      'live' => 'assets.maestro.vhlcentral.com',
      'staging' => 'assets.ms.vhlcentral.com'
    }[env]

    sprockets_asset_parent_dir = 'assets'
    manifest = Sprockets::Manifest.new("public/#{sprockets_asset_parent_dir}")
    sprockets_assets = manifest.assets.values
    bucket = Aws::S3::Resource.new.bucket(bucket_name)

    webpacker_asset_parent_dir = 'packs'
    webpacker_assets = Dir.glob('**/*.{css,gif,jpg,js,js.map,png,svg}', base: "public/#{webpacker_asset_parent_dir}")

    vite_asset_parent_dir = 'vite'
    vite_assets = Dir.glob('**/*.{css,js,js.map,woff2}', base: "public/#{vite_asset_parent_dir}")

    S3AssetUploader.upload_to_s3(bucket: bucket,
                                 assets: sprockets_assets,
                                 asset_parent_dir: sprockets_asset_parent_dir)
    S3AssetUploader.upload_to_s3(bucket: bucket,
                                 assets: webpacker_assets,
                                 asset_parent_dir: webpacker_asset_parent_dir)
    S3AssetUploader.upload_to_s3(bucket: bucket,
                                 assets: vite_assets,
                                 asset_parent_dir: vite_asset_parent_dir)
  end
end
