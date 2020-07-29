# Copyright (c) 2018 SUSE LLC.
#  All Rights Reserved.

#  This program is free software; you can redistribute it and/or
#  modify it under the terms of version 2 or 3 of the GNU General
#  Public License as published by the Free Software Foundation.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program; if not, contact SUSE LLC.

#  To contact SUSE about this file by physical or electronic mail,
#  you may find current contact information at www.suse.com

$LOAD_PATH.unshift(File.expand_path('../../src/lib/', __FILE__))

require 'yast'
require 'yast/rspec'

ENV['Y2DIR'] = File.expand_path('../../src', __FILE__)

srcdir = File.expand_path('../../src', __FILE__)

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
    add_filter '/clients/'
    track_files("#{srcdir}/**/*.rb")
    minimum_coverage 100
  end

  # use coveralls for on-line code coverage reporting at Travis CI
  if ENV['TRAVIS']
    require 'coveralls'
    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::HTMLFormatter,
      Coveralls::SimpleCov::Formatter
    ])
  end
end
