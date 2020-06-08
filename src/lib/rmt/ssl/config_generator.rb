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

require 'erb'
require 'resolv'

module RMT; end
module RMT::SSL; end

class RMT::SSL::ConfigGenerator
  attr_reader :ca_common_name, :server_common_name, :dns_alt_names, :ip_alt_names

  def initialize(hostname, alt_names)
    @ca_common_name = 'RMT Certificate Authority'
    @server_common_name = hostname
    @dns_alt_names = []
    @ip_alt_names = []
    @templates_dir = File.expand_path('./../../../data/rmt', __dir__)

    alt_names.unshift(@server_common_name) unless alt_names.include?(@server_common_name)
    alt_names.each do |alt_name|
      if (alt_name.match(Resolv::IPv4::Regex) || alt_name.match(Resolv::IPv6::Regex))
        @ip_alt_names << alt_name
      else
        @dns_alt_names << alt_name
      end
    end
  end

  def make_ca_config
    template = File.read(File.join(@templates_dir, 'rmt-ca.cnf.erb'))
    ERB.new(template).result(binding)
  end

  def make_server_config
    template = File.read(File.join(@templates_dir, 'rmt-server-cert.cnf.erb'))
    ERB.new(template, nil, '<>').result(binding)
  end
end
