describe SvgContent do
  describe "#svg_content" do
    let(:svg_image) do
      create(
        :media_item_image,
        cdn: true,
        filename: 'images/m00225465_r00161425.svg',
        revision_id: 161425
      )
    end

    let(:svg) do
      '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"></svg>'
    end

    let(:cdn_cache) { double(SvgCache, svg_get: svg, cache_error: nil) }
    let(:s3) { double(Radner::S3Storage) }

    before do
      allow(M3::Application.config).to receive(:s3_media_bucket_name)
        .and_return('media.test.vhlcentral.com')
      allow(SvgCache).to receive(:new).with(
        M3::Application.config.cdn_cache, s3
      ).and_return(cdn_cache)
      allow(Radner::S3Storage).to receive(:new).and_return(s3)
    end

    it "should read the contents from the cdn cache" do
      expected_filepath = svg_image.content_filepath
      expected_cache_key = svg_image.send(:cache_key)
      expect(cdn_cache).to receive(:svg_get).with(
        expected_cache_key, expected_filepath
      ).and_return(svg)

      svg_image.svg_content
    end

    it "creates a cdn cache connection" do
      expect(SvgCache).to receive(:new).with(
        M3::Application.config.cdn_cache, s3
      )

      svg_image.svg_content
    end
  end
end
