# Generated by jeweler
# DO NOT EDIT THIS FILE
# Instead, edit Jeweler::Tasks in Rakefile, and run `rake gemspec`
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{vrowser}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["kimoto"]
  s.date = %q{2012-02-06}
  s.default_executable = %q{vrowser}
  s.description = %q{Server browser for many games (Left4Dead2, TeamFortress2, etc)}
  s.email = %q{sub+peerler@gmail.com}
  s.executables = ["vrowser"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE.txt",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "bin/vrowser",
     "examples/config.yml",
     "lib/plugins/l4d2.rb",
     "lib/vrowser.rb",
     "test/helper.rb",
     "test/test_vrowser.rb"
  ]
  s.homepage = %q{http://github.com/kimoto/vrowser}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Server browser for many games}
  s.test_files = [
    "test/helper.rb",
     "test/test_vrowser.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<thoughtbot-shoulda>, [">= 0"])
    else
      s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
    end
  else
    s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
  end
end
