module Tags
  RUBY_FILES = FileList['**/*.rb'].exclude("pkg")
end

namespace "tags" do
  desc "create TAGS file for emacs file navigation."
  task :emacs => Tags::RUBY_FILES do
    puts "Making Emacs TAGS file"
    sh "ctags -e #{Tags::RUBY_FILES}", :verbose => false
  end
end

task :tags => ["tags:emacs"]
