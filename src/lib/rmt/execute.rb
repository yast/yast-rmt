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

require 'yast'
require 'cheetah'

module RMT; end

# This module is copypasta from version 4 of Yast::Execute.
# Leap 42.* and SLE12 has Yast version 3 which doesn't have `on_target!` method.
# Ideally. this needs to be removed and replaced with Yast::Execute once Leap 15 and SLE15 are out.
class RMT::Execute
  Cheetah.default_options = { logger: Yast::Y2Logger.instance }

  extend Yast::I18n
  textdomain 'rmt'

  def self.on_target(*args)
    popup_error { on_target!(*args) }
  end

  def self.on_target!(*args)
    root = Yast::WFM.scr_root

    if args.last.is_a? ::Hash
      args.last[:chroot] = root
    else
      args.push(chroot: root)
    end

    Cheetah.run(*args)
  end

  private_class_method def self.popup_error(&block)
    block.call
  rescue Cheetah::ExecutionFailed => e
    Yast.import 'Report'
    Yast::Report.Error(
      _(
        "Execution of command \"%<command>s\" failed.\n"\
        "Exit code: %<exitcode>s\n"\
        'Error output: %<stderr>s'
      ) % {
        command:  e.commands.inspect,
        exitcode: e.status.exitstatus,
        stderr:   e.stderr
      }
    )
  end
end
