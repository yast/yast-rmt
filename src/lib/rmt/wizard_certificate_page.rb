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

require 'rmt/certificate/alternative_common_name_dialog'
require 'ui/event_dispatcher'

module RMT; end

class RMT::WizardCertificatePage < Yast::Client
  include ::UI::EventDispatcher

  def initialize(config)
    textdomain 'rmt'
    @config = config
  end

  def render_content
    common_name = get_common_name
    @alt_names = get_alt_names(common_name)

    contents = Frame(
      _('SSL certificate generation'),
      HBox(
        HSpacing(1),
        VBox(
          VSpacing(1),
          Left(
            HSquash(
              MinWidth(30, InputField(Id(:common_name), _('Common name'), common_name))
            )
          ),
          VSpacing(1),
          SelectionBox(
            Id(:alt_common_names),
            _("&Alternative common names:"),
            @alt_names
          ),
          VSpacing(1),
          HBox(
            PushButton(Id(:add_alt_name), Opt(:default, :key_F5), _('Add')),
            PushButton(Id(:remove_alt_name), Opt(:default, :key_F6), _('Remove selected'))
          )
        ),
        HSpacing(1),
      )
    )

    Wizard.SetNextButton(:next, Label.OKButton)
    Wizard.SetContents(
      _('RMT configuration step 3/3'),
      contents,
      '<p>This step of the wizard generates the required SSL certificates.</p>',
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
    finish_dialog(:next)
  end

  def add_alt_name_handler
    dialog = RMT::Certificate::AlternativeCommonNameDialog.new
    alt_name = dialog.run

    return unless alt_name
    @alt_names << alt_name
    UI::ChangeWidget(Id(:alt_common_names), :Items, @alt_names)
  end

  def remove_alt_name_handler
    selected_alt_name = UI.QueryWidget(Id(:alt_common_names), :CurrentItem)
    return unless selected_alt_name
    @alt_names.reject! { |item| item == selected_alt_name }
    UI::ChangeWidget(Id(:alt_common_names), :Items, @alt_names)
  end

  def run
    render_content
    event_loop
  end

  def get_common_name
    result = RMT::Utils.run_command("hostname --long", extended: true)
    result['stdout']
  end

  def get_alt_names(common_name)
    ips = []
    result = RMT::Utils.run_command("ip -f inet -o addr show scope global | awk '{print $4}' | awk -F / '{print $1}' | tr '\n' ','", extended: true)
    ips += result['stdout'].split(',').compact

    result = RMT::Utils.run_command("ip -f inet6 -o addr show scope global | awk '{print $4}' | awk -F / '{print $1}' | tr '\n' ','", extended: true)
    ips += result['stdout'].split(',').compact

    dns_entries = ips.flat_map { |ip| query_dns_entries(ip) }.compact.reject { |item| item == common_name }

    return dns_entries + ips
  end

  def query_dns_entries(ip)
    result = RMT::Utils.run_command(
      "dig +noall +answer +time=2 +tries=1 -x %1 | awk '{print $5}' | sed 's/\\.$//'| tr '\n' '|'",
      ip,
      extended: true
    )

    return result['stdout'].split('|').compact unless result['stdout'].empty?

    result = RMT::Utils.run_command(
      "getent hosts %1 | awk '{print $2}' | sed 's/\\.$//'| tr '\n' '|'",
      ip,
      extended: true
    )

    return result['stdout'].split('|').compact unless result['stdout'].empty?
  end

end
