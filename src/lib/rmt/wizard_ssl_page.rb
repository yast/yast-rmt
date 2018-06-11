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

require 'rmt/ssl/alternative_common_name_dialog'
require 'rmt/ssl/current_ca_password_dialog'
require 'rmt/ssl/config_generator'
require 'rmt/ssl/certificate_generator'
require 'rmt/execute'
require 'ui/event_dispatcher'

module RMT; end

class RMT::WizardSSLPage < Yast::Client # rubocop:disable Metrics/ClassLength
  include ::UI::EventDispatcher
  include Yast::Logger

  def initialize(config)
    textdomain 'rmt'
    @config = config
    @alt_names = query_alt_names
    @cert_generator = RMT::SSL::CertificateGenerator.new
  end

  def render_content
    common_name = query_common_name

    contents = Frame(
      _('SSL certificate generation'),
      HBox(
        HSpacing(1),
        VBox(
          VSpacing(1),
          Left(
            HSquash(
              MinWidth(30, Password(Id(:ca_password), _('Password')))
            )
          ),
          Left(
            HSquash(
              MinWidth(30, Password(Id(:ca_password_confirmation), _('Password confirmation')))
            )
          ),
          VSpacing(1),
          Left(
            HSquash(
              MinWidth(30, InputField(Id(:common_name), _('Common name'), common_name))
            )
          ),
          VSpacing(1),
          SelectionBox(
            Id(:alt_common_names),
            _('&Alternative common names:'),
            @alt_names
          ),
          VSpacing(1),
          HBox(
            PushButton(Id(:add_alt_name), Opt(:default, :key_F5), _('Add')),
            PushButton(Id(:remove_alt_name), Opt(:default, :key_F6), _('Remove selected'))
          )
        ),
        HSpacing(1)
      )
    )

    Wizard.SetContents(
      _('RMT configuration step 3/4'),
      contents,
      _('<p>This step of the wizard generates the required SSL certificates.</p>'),
      true,
      true
    )
  end

  def abort_handler
    finish_dialog(:abort)
  end

  def back_handler
    finish_dialog(:back)
  end

  def next_handler
    common_name = UI.QueryWidget(Id(:common_name), :Value)
    alt_names_items = UI.QueryWidget(Id(:alt_common_names), :Items)
    alt_names = alt_names_items.map { |item| item.params[1] }

    ca_password = UI.QueryWidget(Id(:ca_password), :Value)
    ca_password_confirmation = UI.QueryWidget(Id(:ca_password_confirmation), :Value)

    if !ca_password || ca_password.empty? || ca_password != ca_password_confirmation
      Report.Error(_('Password and confirmation are empty or not equal'))
      return
    end

    @cert_generator.generate(common_name, alt_names, ca_password)

    finish_dialog(:next)
  end

  def add_alt_name_handler
    dialog = RMT::SSL::AlternativeCommonNameDialog.new
    alt_name = dialog.run

    return unless alt_name
    @alt_names << alt_name
    UI::ChangeWidget(Id(:alt_common_names), :Items, @alt_names)
  end

  def remove_alt_name_handler
    selected_alt_name = UI.QueryWidget(Id(:alt_common_names), :CurrentItem)
    return unless selected_alt_name

    selected_index = @alt_names.find_index(selected_alt_name)
    return unless selected_index

    @alt_names.reject! { |item| item == selected_alt_name }
    selected_index = (selected_index >= @alt_names.size) ? @alt_names.size - 1 : selected_index

    UI::ChangeWidget(Id(:alt_common_names), :Items, @alt_names)
    UI::ChangeWidget(Id(:alt_common_names), :CurrentItem, @alt_names[selected_index])
  end

  def run
    if @cert_generator.server_cert_present?
      if @cert_generator.ca_encrypted?
        current_ca_password = RMT::SSL::CurrentCaPasswordDialog.new.run

        if !current_ca_password
          Report.Error(_('SSL certificate password not provided, skipping import.'))
        elsif @cert_generator.valid_password?(current_ca_password)
          Yast::Popup.Message(_('SSL certificates already present and password is valid, skipping generation.'))
        end
      else
        Yast::Popup.Message(_('SSL certificates already present, skipping generation. Please consider encrypting your CA private key!'))
      end
      return finish_dialog(:next)
    end
    render_content
    event_loop
  end

  protected

  def query_common_name
    output = RMT::Execute.on_target!('hostname', '--long', stdout: :capture)
    output.strip
  rescue Cheetah::ExecutionFailed
    'rmt.server'
  end

  def query_alt_names
    ips = []

    %w[inet inet6].each do |addr_type|
      begin
        output = RMT::Execute.on_target!(
          ['ip', '-f', addr_type, '-o', 'addr', 'show', 'scope', 'global'],
          ['awk', '{print $4}'],
          ['awk', '-F', '/', '{print $1}'],
          ['tr', '\n', ','],
          stdout: :capture
        )

        ips += output.split(',').compact
      rescue Cheetah::ExecutionFailed => e
        log.warn "Failed to obtain IP addresses: #{e.stderr}"
      end
    end

    dns_entries = ips.flat_map { |ip| query_dns_entries(ip) }.uniq.compact
    dns_entries + ips
  end

  def query_dns_entries(ip)
    commands = [
      [
        ['dig', '+noall', '+answer', '+time=2', '+tries=1', '-x', ip],
        ['awk', '{print $5}'],
        ['sed', 's/\\.$//'],
        ['tr', '\n', '|']
      ],
      [
        ['getent', 'hosts', ip],
        ['awk', '{print $2}'],
        ['sed', 's/\\.$//'],
        ['tr', '\n', '|']
      ]
    ]

    commands.each do |command|
      begin
        output = RMT::Execute.on_target!(
          *command,
          stdout: :capture
        )

        return output.split('|').compact unless output.empty?
      rescue Cheetah::ExecutionFailed => e
        log.warn "Failed to obtain host names: #{e.stderr}"
      end
    end

    nil
  end
end
