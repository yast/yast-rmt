$LOAD_PATH.unshift(File.expand_path('../../src/lib/', __FILE__))

require 'yast'
require 'yast/rspec'

ENV['Y2DIR'] = File.expand_path('../../src', __FILE__)
