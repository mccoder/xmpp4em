require "rake"

task :default do
  Dir.chdir('spec'){
    sh 'bacon spec_runner.rb'
  }
end

begin
  require "jeweler"
  require "base64"
  require 'lib/xmpp4em'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "xmpp4em"
    gemspec.summary = "EventMachine based XMPP client and component"
    gemspec.description = "Simple XMPP client and component built on EventMachine."
    gemspec.email =  Base64.decode64("bWNjb2Rlci1ub3NwYW1AeWEucnU=")
    gemspec.homepage = "http://github.com/igrigorik/em-synchrony"
    gemspec.authors = ['Aman Gupta', 'Kokorin Denis']
    gemspec.required_ruby_version = ">= 1.9"
	gemspec.version= XMPP4EM::VERSION
	
    gemspec.add_dependency("eventmachine", ">= 0.12.9")
	gemspec.add_dependency("xmpp4r", "= 0.5")
  end

  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end
