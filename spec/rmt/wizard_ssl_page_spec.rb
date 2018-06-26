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

require 'rmt/wizard_ssl_page'

Yast.import 'Wizard'

describe RMT::WizardSSLPage do
  subject(:ssl_page) do
    expect_any_instance_of(described_class).to receive(:query_alt_names).and_return(alt_names)
    described_class.new(config)
  end

  let(:config) { {} }
  let(:generator_double) { instance_double(RMT::SSL::CertificateGenerator) }
  let(:alt_names) { %w[rmt-main.example.com rmt-01.example.com] }

  before do
    allow(RMT::SSL::CertificateGenerator).to receive(:new).and_return(generator_double)
  end

  describe '#render_content' do
    it 'renders UI elements' do
      expect(Yast::Wizard).to receive(:SetContents)

      expect(ssl_page).to receive(:query_common_name)

      ssl_page.render_content
    end
  end

  describe '#abort_handler' do
    it 'finishes when cancel button is clicked' do
      expect(ssl_page).to receive(:finish_dialog).with(:abort)
      ssl_page.abort_handler
    end
  end

  describe '#back_handler' do
    it 'goes back cancel button is clicked' do
      expect(ssl_page).to receive(:finish_dialog).with(:back)
      ssl_page.back_handler
    end
  end

  describe '#next_handler' do
    let(:common_name) { 'rmt.example.com' }
    let(:alt_names_items) { alt_names.map { |i| Yast::Term.new(:Item, i, i) } }
    let(:current_ca_password_dialog_double) { instance_double(RMT::SSL::CurrentCaPasswordDialog) }
    let(:new_ca_password_dialog_double) { instance_double(RMT::SSL::NewCaPasswordDialog) }
    let(:ca_password) { 'foobar' }

    context 'with ca present' do
      context 'with ca encrypted' do
        it 'generates the certificates when next button is clicked' do
          expect(Yast::UI).to receive(:QueryWidget).with(Id(:common_name), :Value).and_return(common_name)
          expect(Yast::UI).to receive(:QueryWidget).with(Id(:alt_common_names), :Items).and_return(alt_names_items)
          expect(generator_double).to receive(:ca_present?).and_return(true)
          allow(generator_double).to receive(:ca_encrypted?).and_return(true)

          expect(RMT::SSL::CurrentCaPasswordDialog).to receive(:new).and_return(current_ca_password_dialog_double)
          expect(current_ca_password_dialog_double).to receive(:run).and_return(ca_password)
          expect(generator_double).to receive(:generate).with(common_name, alt_names, ca_password)

          expect(ssl_page).to receive(:finish_dialog).with(:next)
          ssl_page.next_handler
        end
      end

      context 'with ca unencrypted' do
        it 'generates the certificates when next button is clicked' do
          expect(Yast::UI).to receive(:QueryWidget).with(Id(:common_name), :Value).and_return(common_name)
          expect(Yast::UI).to receive(:QueryWidget).with(Id(:alt_common_names), :Items).and_return(alt_names_items)
          expect(generator_double).to receive(:ca_present?).and_return(true)
          allow(generator_double).to receive(:ca_encrypted?).and_return(false)

          expect(RMT::SSL::CurrentCaPasswordDialog).not_to receive(:new)
          expect(generator_double).to receive(:generate).with(common_name, alt_names, '')

          expect(ssl_page).to receive(:finish_dialog).with(:next)
          ssl_page.next_handler
        end
      end
    end

    context 'with ca empty' do
      it 'generates the certificates when next button is clicked' do
        expect(Yast::UI).to receive(:QueryWidget).with(Id(:common_name), :Value).and_return(common_name)
        expect(Yast::UI).to receive(:QueryWidget).with(Id(:alt_common_names), :Items).and_return(alt_names_items)

        expect(generator_double).to receive(:ca_present?).and_return(false)
        expect(RMT::SSL::NewCaPasswordDialog).to receive(:new).and_return(new_ca_password_dialog_double)
        expect(new_ca_password_dialog_double).to receive(:run).and_return(ca_password)
        expect(generator_double).to receive(:generate)

        expect(ssl_page).to receive(:finish_dialog).with(:next)
        ssl_page.next_handler
      end
    end

    context 'with no ca password' do
      it 'does not generate certificate when ca_password is not provided' do
        expect(Yast::UI).to receive(:QueryWidget).with(Id(:common_name), :Value).and_return(common_name)
        expect(Yast::UI).to receive(:QueryWidget).with(Id(:alt_common_names), :Items).and_return(alt_names_items)

        expect(generator_double).to receive(:ca_present?).and_return(false)
        expect(RMT::SSL::NewCaPasswordDialog).to receive(:new).and_return(new_ca_password_dialog_double)
        expect(new_ca_password_dialog_double).to receive(:run).and_return(nil)
        expect(generator_double).not_to receive(:generate)
        expect(Yast::Popup).to receive(:Error).with('CA password not provided, skipping SSL keys generation.')

        expect(ssl_page).to receive(:finish_dialog).with(:next)
        ssl_page.next_handler
      end
    end
  end

  describe '#add_alt_name_handler' do
    let(:dialog_double) { instance_double(RMT::SSL::AlternativeCommonNameDialog) }

    context 'when alt name dialog is canceled' do
      it 'displays add alt name dialog' do
        expect(RMT::SSL::AlternativeCommonNameDialog).to receive(:new).and_return(dialog_double)
        expect(dialog_double).to receive(:run).and_return(nil)
        ssl_page.add_alt_name_handler
      end
    end

    context 'when alt name dialog returns an alt name' do
      let(:alt_name) { 'alt-name.example.org' }

      it 'displays add alt name dialog' do
        expect(RMT::SSL::AlternativeCommonNameDialog).to receive(:new).and_return(dialog_double)
        expect(dialog_double).to receive(:run).and_return(alt_name)
        expect(Yast::UI).to receive(:ChangeWidget).with(Id(:alt_common_names), :Items, alt_names + [alt_name])
        ssl_page.add_alt_name_handler
      end
    end
  end

  describe '#remove_alt_name_handler' do
    context 'when no item is selected' do
      it "doesn't do anything" do
        expect(Yast::UI).to receive(:QueryWidget).with(Id(:alt_common_names), :CurrentItem).and_return(nil)
        ssl_page.remove_alt_name_handler
      end
    end

    context 'when an item is selected' do
      it 'removes the selected item' do
        expect(Yast::UI).to receive(:QueryWidget).with(Id(:alt_common_names), :CurrentItem).and_return(alt_names[0])
        expect(Yast::UI).to receive(:ChangeWidget).with(Id(:alt_common_names), :Items, [alt_names[1]])
        expect(Yast::UI).to receive(:ChangeWidget).with(Id(:alt_common_names), :CurrentItem, alt_names[1])
        ssl_page.remove_alt_name_handler
      end
    end
  end

  describe '#run' do
    context 'when server certificate is already present' do
      context 'with encrypted' do
        it 'shows proper error message' do
          expect(generator_double).to receive(:server_cert_present?).and_return(true)
          expect(generator_double).to receive(:ca_encrypted?).and_return(true)
          expect(Yast::Popup).to receive(:Message).with(
            'SSL certificates already present, skipping generation.'
          )
          expect(ssl_page).to receive(:finish_dialog).with(:next)
          ssl_page.run
        end
      end

      context 'with non-encrypted' do
        it 'shows a message and finishes' do
          expect(generator_double).to receive(:server_cert_present?).and_return(true)
          expect(generator_double).to receive(:ca_encrypted?).and_return(false)
          expect(Yast::Popup).to receive(:Message).with(
            "SSL certificates already present, skipping generation.\nPlease consider encrypting your CA private key!"
          )
          expect(ssl_page).to receive(:finish_dialog).with(:next)
          ssl_page.run
        end
      end
    end

    context 'when certificates are not present' do
      it 'renders content and enters the event loop' do
        expect(generator_double).to receive(:server_cert_present?).and_return(false)
        expect(ssl_page).to receive(:render_content)
        expect(ssl_page).to receive(:event_loop)
        ssl_page.run
      end
    end
  end

  describe '#query_common_name' do
    it 'queries the long hostname' do
      expect(RMT::Execute).to receive(:on_target!).with('hostname', '--long', stdout: :capture).and_return("\n\n\nexample.org\n\n")
      expect(ssl_page.send(:query_common_name)).to eq('example.org')
    end

    it 'handles exceptions and sets the default common name' do
      expect(RMT::Execute).to receive(:on_target!).with('hostname', '--long', stdout: :capture).and_raise(
        Cheetah::ExecutionFailed.new('command', 255, '', 'Something went wrong')
      )
      expect(ssl_page.send(:query_common_name)).to eq('rmt.server')
    end
  end

  describe '#query_alt_names' do
    subject(:ssl_page) do
      expect(RMT::Execute).to receive(:on_target!).and_return('').exactly(2).times
      described_class.new(config)
    end

    let(:ipv4s) { %w[1.1.1.1 2.2.2.2 3.3.3.3] }
    let(:ipv6s) { %w[1111:2222:3333:4444:5555:6666:7777:8888 8888:7777:6666:5555:4444:3333:2222:1111] }
    let(:dns_name_1) { 'foo.example.org' }
    let(:dns_name_2) { 'bar.example.org' }

    it 'queries IPs and DNS names' do
      ipv4s.each do |ipv4|
        expect(ssl_page).to receive(:query_dns_entries).with(ipv4).and_return([dns_name_1])
      end

      ipv6s.each do |ipv6|
        expect(ssl_page).to receive(:query_dns_entries).with(ipv6).and_return([dns_name_2])
      end

      expect(RMT::Execute).to receive(:on_target!).with(
        ['ip', '-f', 'inet', '-o', 'addr', 'show', 'scope', 'global'],
        ['awk', '{print $4}'],
        ['awk', '-F', '/', '{print $1}'],
        ['tr', '\\n', ','],
        { stdout: :capture }
      ).and_return(ipv4s.join(','))

      expect(RMT::Execute).to receive(:on_target!).with(
        ['ip', '-f', 'inet6', '-o', 'addr', 'show', 'scope', 'global'],
        ['awk', '{print $4}'],
        ['awk', '-F', '/', '{print $1}'],
        ['tr', '\\n', ','],
        { stdout: :capture }
      ).and_return(ipv6s.join(','))


      expect(ssl_page.send(:query_alt_names)).to eq([dns_name_1] + [dns_name_2] + ipv4s + ipv6s)
    end

    it 'handles exceptions and writes errors to log' do
      expect(RMT::Execute).to receive(:on_target!).with(
        ['ip', '-f', 'inet', '-o', 'addr', 'show', 'scope', 'global'],
        ['awk', '{print $4}'],
        ['awk', '-F', '/', '{print $1}'],
        ['tr', '\\n', ','],
        { stdout: :capture }
      ).and_raise(Cheetah::ExecutionFailed.new('command', 255, '', 'Something went wrong'))

      expect(RMT::Execute).to receive(:on_target!).with(
        ['ip', '-f', 'inet6', '-o', 'addr', 'show', 'scope', 'global'],
        ['awk', '{print $4}'],
        ['awk', '-F', '/', '{print $1}'],
        ['tr', '\\n', ','],
        { stdout: :capture }
      ).and_raise(Cheetah::ExecutionFailed.new('command', 255, '', 'Something went wrong'))

      expect_any_instance_of(Yast::Y2Logger).to receive(:warn).with('Failed to obtain IP addresses: Something went wrong').exactly(2).times

      expect(ssl_page.send(:query_alt_names)).to eq([])
    end
  end

  describe '#query_dns_entries' do
    it 'queries DNS' do
      expect(RMT::Execute).to receive(:on_target!).with(
        ['dig', '+noall', '+answer', '+time=2', '+tries=1', '-x', 'foo'],
        ['awk', '{print $5}'],
        ['sed', 's/\\.$//'],
        ['tr', '\\n', '|'],
        { stdout: :capture }
      ).and_return('foo.example.org')

      expect(ssl_page.send(:query_dns_entries, 'foo')).to eq(['foo.example.org'])
    end

    it 'queries hosts file when there are no DNS results' do
      expect(RMT::Execute).to receive(:on_target!).with(
        ['dig', '+noall', '+answer', '+time=2', '+tries=1', '-x', 'foo'],
        ['awk', '{print $5}'],
        ['sed', 's/\\.$//'],
        ['tr', '\\n', '|'],
        { stdout: :capture }
      ).and_return('')

      expect(RMT::Execute).to receive(:on_target!).with(
        ['getent', 'hosts', 'foo'],
        ['awk', '{print $2}'],
        ['sed', 's/\\.$//'],
        ['tr', '\\n', '|'],
        { stdout: :capture }
      ).and_return('bar.example.org')

      expect(ssl_page.send(:query_dns_entries, 'foo')).to eq(['bar.example.org'])
    end

    it 'handles exceptions and writes errors to log' do
      expect(RMT::Execute).to receive(:on_target!).with(
        ['dig', '+noall', '+answer', '+time=2', '+tries=1', '-x', 'foo'],
        ['awk', '{print $5}'],
        ['sed', 's/\\.$//'],
        ['tr', '\\n', '|'],
        { stdout: :capture }
      ).and_raise(Cheetah::ExecutionFailed.new('command', 255, '', 'Something went wrong'))

      expect(RMT::Execute).to receive(:on_target!).with(
        ['getent', 'hosts', 'foo'],
        ['awk', '{print $2}'],
        ['sed', 's/\\.$//'],
        ['tr', '\\n', '|'],
        { stdout: :capture }
      ).and_raise(Cheetah::ExecutionFailed.new('command', 255, '', 'Something went wrong'))

      expect_any_instance_of(Yast::Y2Logger).to receive(:warn).with('Failed to obtain host names: Something went wrong').exactly(2).times

      expect(ssl_page.send(:query_dns_entries, 'foo')).to eq(nil)
    end
  end
end
