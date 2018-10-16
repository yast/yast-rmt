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

require 'rmt/wizard_firewall_page'

describe RMT::WizardFirewallPage do
  subject(:firewall_page) { described_class.new }

  let(:firewalld_double) { instance_double(Y2Firewall::Firewalld) }

  before { allow(Y2Firewall::Firewalld).to receive(:instance).and_return(firewalld_double) }

  describe '#contents' do
    context 'with firewalld enabled' do
      it 'renders firewall widget' do
        expect(firewalld_double).to receive(:installed?).and_return(true)
        expect(firewalld_double).to receive(:enabled?).and_return(true)
        expect(RMT::WizardFirewallPage::FirewallWidget).to receive(:new)

        firewall_page.contents
      end
    end

    context 'without firewalld enabled' do
      it 'only renders info text' do
        expect(firewalld_double).to receive(:installed?).and_return(true)
        expect(firewalld_double).to receive(:enabled?).and_return(false)
        expect(RMT::WizardFirewallPage::FirewallWidget).not_to receive(:new)
        expect(firewall_page).to receive(:Label).with(
          "Firewalld is not enabled.\n\nIf you enable firewalld later,\nremember to open the firewall ports for HTTP and HTTPS."
        )

        firewall_page.contents
      end
    end
  end
end
