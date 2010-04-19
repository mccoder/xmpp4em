#!/usr/bin/env gem build
# encoding: utf-8

require "base64"
require 'lib/xmpp4em'

Gem::Specification.new do |s|
  s.name = "xmpp4em"
  s.version = XMPP4EM::VERSION
  s.authors = ['Aman Gupta', 'Kokorin Denis']
  s.homepage = "http://github.com/mccoder/xmpp4em"
  s.summary = "EventMachine based XMPP client"
  s.email = Base64.decode64("bWNjb2Rlci1ub3NwYW1AeWEucnU=")

  # files
  s.files = ['README', 'Rakefile', 'History.txt'] + Dir["lib/**/*.rb"]
    
  s.require_paths = ["lib"]

  # Ruby version
  s.required_ruby_version = ::Gem::Requirement.new("~> 1.9")
  s.add_dependency('eventmachine', '>=0.12.10')
  s.add_dependency('xmpp4r', '>=0.5')
  s.add_dependency('evma_xmlpushparser', '>=0.0.1')
end