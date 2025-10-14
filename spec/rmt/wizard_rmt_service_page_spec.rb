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

require 'rmt/wizard_rmt_service_page'

Yast.import 'Wizard'

describe RMT::WizardRMTServicePage do
  subject(:service_page) { described_class.new(config) }

  let(:config) do
    {
      'scc' => {
        'username' => 'UC666'
      },
      'database' => {
        'username' => 'user_mcuserface',
        'password' => 'test',
        'host' => 'localhost',
        'database' => 'rmt'
      }
    }
  end

  describe '#next_handler' do
    it 'finishes when next button is pressed' do
      expect(service_page).to receive(:finish_dialog).with(:next)
      service_page.next_handler
    end
  end

  describe '#abort_handler' do
    it 'finishes when abort button is pressed' do
      expect(service_page).to receive(:finish_dialog).with(:abort)
      service_page.abort_handler
    end
  end

  describe '#back_handler' do
    it 'finishes when back button is pressed' do
      expect(service_page).to receive(:finish_dialog).with(:back)
      service_page.back_handler
    end
  end

  describe '#render_content' do
    it 'renders UI elements' do
      expect(Yast::Wizard).to receive(:SetContents)
      service_page.render_content
    end
  end

  describe '#run' do
    context 'successful run' do
      context 'restarting succeeds' do
        it 'reloads and restarts the services and continues' do
          expect(service_page).to receive(:render_content)
          expect(Yast::Popup).to receive(:Feedback).and_call_original
          expect(service_page).to receive(:rmt_service_start).and_return(true)
          expect(Yast::Popup).to receive(:Feedback).and_call_original
          expect(service_page).to receive(:nginx_service_reload).and_return(true)
          expect(service_page).to receive(:event_loop)
          service_page.run
        end
      end
    end

    context 'unsuccessful run' do
      context 'restarting fails' do
        it 'shows an error and continues' do
          expect(service_page).to receive(:render_content)
          expect(service_page).to receive(:rmt_service_start).and_return(false)
          expect(Yast::Report).to receive(:Error).with('Failed to enable and restart RMT services and timers')
          expect(service_page).to receive(:nginx_service_reload).and_return(false)
          expect(Yast::Report).to receive(:Error).with("Failed to reload service for 'nginx'")
          expect(service_page).to receive(:event_loop)
          service_page.run
        end
      end
    end
  end

  describe '#nginx_service_reload' do
    context 'succeeds to reload' do
      it 'returns true' do
        expect(Yast::Service).to receive(:Reload).with('nginx').and_return(true)
        service_page.nginx_service_reload
      end
    end

    context 'fails to reload' do
      it 'returns false' do
        expect(Yast::Service).to receive(:Reload).with('nginx').and_return(false)
        service_page.nginx_service_reload
      end
    end
  end

  describe '#rmt_service_start' do
    context 'when restarting the service succeeds' do
      it 'shows confirmation' do
        expect(Yast::Service).to receive(:Enable).with('rmt-server').and_return(true)
        expect(Yast::Service).to receive(:Restart).with('rmt-server').and_return(true)
        %w[rmt-server-sync.timer rmt-server-mirror.timer rmt-server-systems-scc-sync.timer].each do |unit|
          expect(RMT::Execute).to receive(:on_target!).with('systemctl', 'enable', unit).and_return(true)
          expect(RMT::Execute).to receive(:on_target!).with('systemctl', 'start', unit).and_return(true)
        end
        service_page.rmt_service_start
      end
    end

    context 'when restarting the service fails' do
      it 'displays error' do
        expect(Yast::Service).to receive(:Enable).with('rmt-server').and_return(true)
        expect(Yast::Service).to receive(:Restart).with('rmt-server').and_return(false)
        expect(service_page.rmt_service_start).to be false
      end
    end
  end
end
