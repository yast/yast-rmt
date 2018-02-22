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

require 'rmt/wizard'

Yast.import 'Wizard'
Yast.import 'Sequencer'

describe RMT::Wizard do
  subject(:wizard) { described_class.new }

  let(:config) { { foo: 'bar' } }

  before do
  end

  it 'runs and goes through the sequence' do
    expect(RMT::Base).to receive(:read_config_file).and_return({})

    expect(Yast::Wizard).to receive(:CreateDialog)
    expect(Yast::Wizard).to receive(:SetTitleIcon)

    expect(wizard).to receive(:step1).and_return(:next)
    expect(wizard).to receive(:step2).and_return(:next)

    expect(Yast::UI).to receive(:CloseDialog)
    wizard.run
  end
end
