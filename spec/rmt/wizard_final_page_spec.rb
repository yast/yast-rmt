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

require 'rmt/wizard_final_page'

Yast.import 'Wizard'

describe RMT::WizardFinalPage do
  subject(:final_page) { described_class.new(config) }

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
      expect(final_page).to receive(:finish_dialog).with(:next)
      final_page.next_handler
    end
  end

  describe '#abort_handler' do
    it 'finishes when abort button is pressed' do
      expect(final_page).to receive(:finish_dialog).with(:abort)
      final_page.abort_handler
    end
  end

  describe '#back_handler' do
    it 'finishes when back button is pressed' do
      expect(final_page).to receive(:finish_dialog).with(:back)
      final_page.back_handler
    end
  end

  describe '#render_content' do
    it 'renders UI elements' do
      expect(Yast::Wizard).to receive(:SetContents)
      final_page.render_content
    end
  end

  describe '#run' do
    it 'restarts rmt-server service and enters event loop' do
      expect(final_page).to receive(:render_content)
      expect(final_page).to receive(:event_loop)
      final_page.run
    end
  end
end
