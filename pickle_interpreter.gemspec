Gem::Specification.new do |s|
  s.name        = 'pickle-interpreter'
  s.version     = '0.1.0'
  s.date        = '2014-06-10'
  s.summary     = "A Ruby Pickle interpreter to unpickle Python objects"
  s.description = "A library to read pickled objects from pythong in Ruby"
  s.authors     = ["Jonathan Bartlett"]
  s.email       = 'jonathan@newmedio.com'
  s.files       = FileList['lib/**/*.rb',
                           '[A-Z]*',
                           'test/**/*']
  s.homepage    = 'http://github.com/newmedio/pickle-interpreter'
  s.test_files  = FileList['test/**/test_*.rb']
end
