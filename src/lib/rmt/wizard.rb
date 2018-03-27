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

require 'rmt/utils'
require 'rmt/wizard_scc_page'
require 'rmt/wizard_maria_db_page'
require 'rmt/wizard_ssl_page'

module RMT
end

class RMT::Wizard < Yast::Client
  include Yast::Logger

  def initialize
    Yast.import 'UI'
    Yast.import 'Wizard'
    Yast.import 'Sequencer'
    Yast.import 'Report'
    Yast.import 'String'
    Yast.import 'SystemdService'
    Yast.import 'Confirm'

    textdomain 'rmt'

    @config = RMT::Utils.read_config_file
  end

  def step1
    page = RMT::WizardSCCPage.new(@config)
    page.run
  end

  def step2
    page = RMT::WizardMariaDBPage.new(@config)
    page.run
  end

  def run
    return unless Yast::Confirm.MustBeRoot

    aliases = {
      'step1' => -> { step1 },
      'step2' => -> { step2 },
      'step3' => -> { RMT::WizardSSLPage.new(@config).run }
    }

    sequence = {
      'ws_start' => 'step1',
      'step1'   => { abort: :abort, next: 'step2' },
      'step2'   => { abort: :abort, next: 'step3' },
      'step3'   => { abort: :abort, next: :next }
    }

    Wizard.CreateDialog()
    Wizard.SetTitleIcon('yast-rmt')

    Sequencer.Run(aliases, sequence)

    UI.CloseDialog()
  end
end
