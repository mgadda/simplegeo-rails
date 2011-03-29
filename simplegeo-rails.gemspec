# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "simplegeo-rails/version"

Gem::Specification.new do |s|
  s.name        = "simplegeo-rails"
  s.version     = Simplegeo::Rails::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Matt Gadda"]
  s.email       = ["mgadda@gmail.com"]
  s.homepage    = "http://github.com/mgadda/simplegeo-rails"
  s.summary     = %q{Provides better integration between simplegeo-ruby and rails}
  s.description = %q{Simplegeo-rails provides a set of objects to make integrating simplegeo's api in your rails application easier.}

  s.rubyforge_project = "simplegeo-rails"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_runtime_dependency(%q<activemodel>, ["~> 3.0.3"])
  s.add_runtime_dependency(%q<simplegeo>, '>= 0.2.1')
  
end
