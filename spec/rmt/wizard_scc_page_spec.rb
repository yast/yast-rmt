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

  let(:config) { { 'scc' => { 'username' => 'user_mcuserface', 'password' => 'test', 'sync_systems' => true } } }

  describe '#render_content' do
    it 'renders UI elements' do
      expect(Yast::Wizard).to receive(:SetAbortButton).with(:abort, Yast::Label.CancelButton)
      expect(Yast::Wizard).to receive(:SetNextButton).with(:next, Yast::Label.NextButton)
      expect(Yast::Wizard).to receive(:SetBackButton).with(:skip, Yast::Label.SkipButton)
      expect(Yast::Wizard).to receive(:SetContents)

      expect(Yast::UI).to receive(:ChangeWidget).with(Id(:scc_username), :Value, config['scc']['username'])
      expect(Yast::UI).to receive(:ChangeWidget).with(Id(:scc_password), :Value, config['scc']['password'])
      expect(Yast::UI).to receive(:ChangeWidget).with(Id(:scc_sync_systems), :Value, config['scc']['sync_systems'])

      scc_page.render_content
    end
  end

  describe '#abort_handler' do
    it 'finishes when cancel button is clicked' do
      expect(scc_page).to receive(:finish_dialog).with(:abort)
      scc_page.abort_handler
    end
  end

  describe '#skip_handler' do
    let(:popup_params) do
      [
        'Skip SCC registration?',
        "This is only recommended for air-gapped environments.\nRMT will not be able to sync and mirror data.\n\nDo you want to continue?",
        'Ignore and continue',
        'Go back',
        :focus_no
      ]
    end

    context 'when cancel is clicked' do
      it 'stays on the same page' do
        expect(Yast::Popup).to receive(:AnyQuestion).with(*popup_params).and_return(false)
        expect(scc_page).not_to receive(:finish_dialog)
        scc_page.skip_handler
      end
    end

    context 'when ignore continue is clicked' do
      it 'goes to the next page' do
        expect(Yast::Popup).to receive(:AnyQuestion).with(*popup_params).and_return(true)
        expect(scc_page).to receive(:finish_dialog).with(:next)
        expect(RMT::Utils).to receive(:write_config_file).with(config)
        scc_page.skip_handler
      end
    end
  end

  describe '#next_handler' do
    before do
      expect(Yast::UI).to receive(:QueryWidget).with(Id(:scc_username), :Value)
      expect(Yast::UI).to receive(:QueryWidget).with(Id(:scc_password), :Value)
      expect(Yast::UI).to receive(:QueryWidget).with(Id(:scc_sync_systems), :Value)
    end

    context "when SCC credentials aren't valid and the error is not ignored" do
      it 'stays on the same page' do
        expect(scc_page).to receive(:scc_credentials_valid?).and_return(false)
        expect(Yast::Popup).to receive(:AnyQuestion).and_return(false)
        expect(scc_page).not_to receive(:finish_dialog)
        scc_page.next_handler
      end
    end

    context "when SCC credentials aren't valid and the error is ignored" do
      it 'goes to the next page' do
        expect(scc_page).to receive(:scc_credentials_valid?).and_return(false)
        expect(Yast::Popup).to receive(:AnyQuestion).and_return(true)
        expect(RMT::Utils).to receive(:write_config_file).with(config)
        expect(scc_page).to receive(:finish_dialog).with(:next)
        scc_page.next_handler
      end
    end

    context 'when SCC credentials are valid' do
      it 'goes to the next page' do
        expect(scc_page).to receive(:scc_credentials_valid?).and_return(true)
        expect(Yast::Popup).not_to receive(:AnyQuestion)
        expect(RMT::Utils).to receive(:write_config_file).with(config)
        expect(scc_page).to receive(:finish_dialog).with(:next)
        scc_page.next_handler
      end
    end
  end

  describe '#run' do
    it 'renders content and runs the event loop' do
      expect(scc_page).to receive(:render_content)
      expect(scc_page).to receive(:event_loop)
      scc_page.run
    end
  end

  describe '#scc_credentials_valid?' do
    before do
      expect(Yast::UI).to receive(:OpenDialog)
      expect(Yast::UI).to receive(:CloseDialog)

      expect_any_instance_of(Net::HTTP::Get).to receive(:basic_auth).with(config['scc']['username'], config['scc']['password'])
    end

    context 'when the request completes without errors' do
      before do
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

    context 'when SCC times out and the user chooses not to try again' do
      before do
        expect(Yast::Popup).to receive(:ErrorAnyQuestion).and_return(false)
        expect(Net::HTTP).to receive(:start).and_raise(Net::ReadTimeout)
      end

      context 'and the user chooses to not try again' do
        it 'returns false' do
          expect(scc_page.scc_credentials_valid?).to be(false)
        end
      end
    end

    context 'when SCC times out and the user chooses to try again' do
      before do
        expect(Yast::Popup).to receive(:ErrorAnyQuestion).and_return(true)
        expect(Net::HTTP).to receive(:start).and_raise(Net::ReadTimeout)
        expect(Net::HTTP).to receive(:start).and_return(response_double)
      end

      let(:response_double) { instance_double(Net::HTTPResponse) }

      context 'when SCC responds quickly and the HTTP response code is 200' do
        before do
          expect(response_double).to receive(:code).and_return(200)
        end

        it 'returns true' do
          expect(scc_page.scc_credentials_valid?).to be(true)
        end
      end

      context 'when SCC responds quickly and the HTTP response code is not 200' do
        before do
          expect(response_double).to receive(:code).and_return(401)
        end

        it 'returns false' do
          expect(scc_page.scc_credentials_valid?).to be(false)
        end
      end
    end
  end
end
