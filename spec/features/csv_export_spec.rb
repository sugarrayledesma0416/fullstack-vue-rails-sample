#encoding: utf-8

feature 'CSV Export', test_debt: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers

  let(:editor) { create(:editor) }
  let(:program) { create(:program, family: 'vista_online_learning') }
  let(:vocab_group_media_item) { MediaItem.new(:filename => 'test.vocab_group.zip', :media_type => 'vocab_group') }
  let(:zip_filename) { 'spec/fixtures/media_items/test.vocab_group.zip' }
  let(:vocab_group_content) { File.read(zip_filename) }

  before do
    vocab_group_media_item.id = 1000 # the id specified in the vocab_list xml
    vocab_group_media_item.save!
    vocab_group_media_item.payload = vocab_group_content
    @flash_cards_activity = create_flashcards_activity(program, {title: "<h1>&eacute;lan</h1>\t Baz\n Foo \u{00D1}aca"})
    @vocab_list_activity = create_vocab_group_activity_model(program)
    initialize_program_access_client_calls_for_instructor(editor, program)
    log_in_as(editor)
    @lesson = @flash_cards_activity.lesson
    @strand = @flash_cards_activity.strand
  end

  after do
    %w(abbr2e_maestro3_vtext_activity_links.csv abbr2e_maestro3_vtext_strand_links.csv abbr2e_maestro3_vtext_vocab_links.csv).each do |file|
      file_path = Rails.root.join('public', 'tmp', file)
      FileUtils.remove_file(file_path) if File.exist?(file_path)
    end
  end

  scenario 'Go to Activity Links' do
    editor.roles << Role.new(name: Role::VTEXT_CREATOR)
    visit vtext_export_path(program)
    click_link('Activity Links')
    expect(page.response_headers['Content-Disposition']).to include VtextDataGenerator.new(program.id).activity_links_file.public_url
    expect(page.response_headers['Content-Type']).to include 'windows-1252'

    parsed_csv = CSV.parse(page.body.force_encoding('utf-8'))
    href = activity_permalink_url(@flash_cards_activity, host: 'm3a.vhlcentral.com')
    #test if csv has headers (Activity Link)
    expect(parsed_csv[0]).to eq(['cmd', 'href', 'activity_name', 'lesson', 'strand'])
    expect(parsed_csv[1]).to eq(["open_m3_activity('#{@flash_cards_activity.id}');", href, "élan Baz Foo Ñaca", @lesson.name, @strand.name])
  end

  scenario  'Go to Strand Links' do
    editor.roles << Role.new(name: Role::VTEXT_CREATOR)
    visit vtext_export_path(program)
    click_link('Strand Links')
    expect(page.response_headers['Content-Disposition']).to include VtextDataGenerator.new(program.id).strand_links_file.public_url
    expect(page.response_headers['Content-Type']).to include 'windows-1252'

    parsed_csv = CSV.parse(page.body.force_encoding('utf-8'))
    href = student_strand_permalink_url(@lesson, @strand.location, host: 'm3a.vhlcentral.com')
    #test if csv has headers (Strand Link)
    expect(parsed_csv[0]).to eq([ 'cmd', 'href', 'activity_name', 'lesson', 'strand'])
    expect(parsed_csv[1]).to eq(["open_m3_toc_location('#{@lesson.id}', '#{@strand.location}');", href, '', @lesson.display_name, @strand.name])
  end

  scenario  'Go to Vocab Links' do
    editor.roles << Role.new(name: Role::VTEXT_CREATOR)
    visit vtext_export_path(program)
    click_link('Vocab Links')
    expect(page.response_headers['Content-Disposition']).to include VtextDataGenerator.new(program.id).vocab_links_file.public_url
    expect(page.response_headers['Content-Type']).to include 'windows-1252'

    parsed_csv = CSV.parse(page.body.force_encoding('utf-8'))
    #test if csv has headers (Vocab Link)
    expect(parsed_csv[0]).to eq(['BookTitle', 'Lesson', 'Strand', 'Page', 'Link Type', 'Activity name', 'Placement', 'Nav Code', 'Link'])
    expect(parsed_csv[1]).to eq([program.title, @lesson.name, @vocab_list_activity.strand.name, '', 'Audio',
     '', 'el ascensor', '', "/media_items/#{ENV['RAILS_ENV']}/vocab_group/0000/1000/VIS4e_L05_TXT_Vocab_ascensor.mp3"])
  end
end
