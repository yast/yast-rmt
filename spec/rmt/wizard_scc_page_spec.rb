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

require 'rmt/wizard_scc_page'

Yast.import 'Wizard'

describe RMT::WizardSCCPage do
  subject(:scc_page) { described_class.new(config) }

  let(:config) { { 'scc' => { 'username' => 'user_mcuserface', 'password' => 'test' } } }

  describe '#run' do
    before do
      expect(Yast::Wizard).to receive(:SetAbortButton).with(:abort, Yast::Label.CancelButton)
      expect(Yast::Wizard).to receive(:SetNextButton).with(:next, Yast::Label.NextButton)
      expect(Yast::Wizard).to receive(:SetContents)
      expect(Yast::Wizard).to receive(:DisableBackButton)

      expect(Yast::UI).to receive(:ChangeWidget).with(Id(:scc_username), :Value, config['scc']['username'])
      expect(Yast::UI).to receive(:ChangeWidget).with(Id(:scc_password), :Value, config['scc']['password'])
    end

    context 'when cancel button is clicked' do
      it 'finishes' do
        expect(Yast::UI).to receive(:UserInput).and_return(:cancel)
        expect(scc_page.run).to be(:cancel)
      end
    end

    context 'when SCC credentials are valid' do
      it 'moves on to the next screen' do
        expect(Yast::UI).to receive(:UserInput).exactly(2).times.and_return(:next)

        expect(Yast::UI).to receive(:QueryWidget).with(Id(:scc_username), :Value).exactly(2).times
        expect(Yast::UI).to receive(:QueryWidget).with(Id(:scc_password), :Value).exactly(2).times

        expect(scc_page).to receive(:scc_credentials_valid?).and_return(false, true)

        expect(Yast::Popup).to receive(:AnyQuestion).and_return(false)

        expect(scc_page.run).to be(:next)
      end
    end

    context 'when SCC credentials are invalid' do
      it 'is possible to ignore the error' do
        expect(Yast::UI).to receive(:UserInput).exactly(2).times.and_return(:next)

        expect(Yast::UI).to receive(:QueryWidget).with(Id(:scc_username), :Value).exactly(2).times
        expect(Yast::UI).to receive(:QueryWidget).with(Id(:scc_password), :Value).exactly(2).times

        expect(scc_page).to receive(:scc_credentials_valid?).and_return(false, false)

        expect(Yast::Popup).to receive(:AnyQuestion).and_return(false, true)

        expect(scc_page.run).to be(:next)
      end
    end
  end

  describe '#scc_credentials_valid?' do
    before do
      expect(Yast::UI).to receive(:OpenDialog)
      expect(Yast::UI).to receive(:CloseDialog)

      expect_any_instance_of(Net::HTTP::Get).to receive(:basic_auth).with(config['scc']['username'], config['scc']['password'])

      expect(Net::HTTP).to receive(:start).and_return(response_double)
      expect(response_double).to receive(:code).and_return(response_code)
    end

    let(:response_double) { instance_double(Net::HTTPResponse) }

    context 'when HTTP response code is 200' do
      let(:response_code) { '200' }

      it 'returns true' do
        expect(scc_page.scc_credentials_valid?).to be(true)
      end
    end

    context 'when HTTP response code is not 200' do
      let(:response_code) { '401' }

      it 'returns false' do
        expect(scc_page.scc_credentials_valid?).to be(false)
      end
    end
  end
end
