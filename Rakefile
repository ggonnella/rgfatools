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
