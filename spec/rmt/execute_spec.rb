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

require 'rmt/execute'

Yast.import 'Report'

describe RMT::Execute do
  describe '.on_target' do
    let(:exit_double) { instance_double(Process::Status) }

    it 'executes the command' do
      expect(described_class).to receive(:on_target!)
      described_class.on_target
    end

    it 'shows an error message when an exception ocurrs' do
      expect(exit_double).to receive(:exitstatus).and_return(255)
      expect(described_class).to receive(:on_target!).and_raise(Cheetah::ExecutionFailed.new('command', exit_double, '', 'Something went wrong'))
      expect(Yast::Report).to receive(:Error)
      described_class.on_target
    end
  end

  describe '.on_target!' do
    let(:chroot) { '/tmp' }

    it 'appends chroot and runs command when args item is not a hash' do
      expect(Yast::WFM).to receive(:scr_root).and_return(chroot)
      expect(Cheetah).to receive(:run).with('cmd', { chroot: chroot })
      described_class.on_target!('cmd')
    end

    it 'appends chroot and runs command when args item is a hash' do
      expect(Yast::WFM).to receive(:scr_root).and_return(chroot)
      expect(Cheetah).to receive(:run).with('cmd', { foo: 'bar', chroot: chroot })
      described_class.on_target!('cmd', { foo: 'bar' })
    end
  end
end
