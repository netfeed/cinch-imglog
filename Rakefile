require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "cinch-imglog"
    gem.summary = %Q{An image log for Cinch}
    gem.description = %Q{An image log to be used together with ImgLog}
    gem.email = "victor.bergoo@gmail.com"
    gem.homepage = "http://github.com/netfeed/cinch-imglog"
    gem.authors = ["Victor Bergoo"]
    gem.add_dependency "cinch"
    gem.add_dependency "curb"
    gem.add_dependency "mini_magick"
    gem.add_dependency "json"
    gem.files = ["lib/**/*.rb", "README.rdoc", "LICENSE"]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end
