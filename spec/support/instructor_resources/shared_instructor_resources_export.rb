RSpec.shared_context 'with units and lessons setup' do
  let(:program) { create(:program_with_lessons, prefix_abbreviation: 'PREFIXAB_E3') }
  let(:csv_path) { File.join('/tmp', "#{program.prefix_abbreviation}_m3_resources.csv") }
  let(:s3_bucket) do
    instance_double(
      Radner::S3Storage,
      file_exist?: true,
      fetch: 'file_contents',
      upload_file: true,
      bucket: instance_double(
        Aws::S3::Bucket,
        object: s3_object
      )
    )
  end
  let(:s3_object) do
    instance_double(Aws::S3::Object, upload_file: true, exists?: true)
  end
end
