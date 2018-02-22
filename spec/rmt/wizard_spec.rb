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
  let(:scc_page_double) { instance_double(RMT::WizardSCCPage) }
  let(:db_page_double) { instance_double(RMT::WizardMariaDBPage) }

  it 'runs and goes through the sequence' do
    expect(RMT::Base).to receive(:read_config_file).and_return({})

    expect(Yast::Wizard).to receive(:CreateDialog)
    expect(Yast::Wizard).to receive(:SetTitleIcon)

    expect(RMT::WizardSCCPage).to receive(:new).and_return(scc_page_double)
    expect(scc_page_double).to receive(:run).and_return(:next)

    expect(RMT::WizardMariaDBPage).to receive(:new).and_return(db_page_double)
    expect(db_page_double).to receive(:run).and_return(:next)

    expect(Yast::UI).to receive(:CloseDialog)
    wizard.run
  end
end
