require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << 'test'
end

desc "Run tests"
task :default => :test

desc "Build gem"
task :build do
  system("gem build gfatools.gemspec")
end

desc "Install gem"
task :install => :build do
  system("gem install gfatools")
end

desc "Rm files created by rake build"
task :clean do
  system("rm -f gfatools-*.gem")
end

# make documentation generation tasks
# available only if yard gem is installed
begin
  require "yard"
  YARD::Tags::Library.define_tag("Developer notes", :developer)
  YARD::Rake::YardocTask.new do |t|
    t.files   = ['lib/**/*.rb']
    t.stats_options = ['--list-undoc']
  end
rescue LoadError
end

desc "Create a PDF documentation"
task :pdf do
  system("yard2.0 --one-file -o pdfdoc")
  system("wkhtmltopdf cover pdfdoc/cover.html "+
                     "toc "+
                     "pdfdoc/index.html "+
                     "--user-style-sheet pdfdoc/print.css "+
                     "pdfdoc/rgfatools-api-1.0.1.pdf")
end
