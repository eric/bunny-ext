# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "bunny-ext/version"

Gem::Specification.new do |s|
  s.name        = "bunny-ext"
  s.version     = Bunny::Ext::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Stefan Kaes", "Pascal Friederich"]
  s.email       = ["developers@xing.com"]
  s.homepage    = ""
  s.summary     = %q{Reliable socket timeouts for the Bunny amqp gem}

  s.rubyforge_project = "bunny-ext"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_dependency('bunny', '= 0.6.0')
end
