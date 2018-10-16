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

require 'y2firewall/firewalld'
require 'rmt/utils'
require 'cwm/dialog'
require 'cwm/custom_widget'

Yast.import 'CWMFirewallInterfaces'

module RMT; end

class RMT::WizardFirewallPage < CWM::Dialog
  def initialize
    textdomain 'rmt'
  end

  def title
    _('RMT configuration step 4/5')
  end

  def abort_button
    Yast::Label.CancelButton # to be consistent with the other pages
  end

  def contents
    if firewalld.installed? && firewalld.enabled?
      HBox(
        HStretch(),
        FirewallWidget.new,
        HStretch()
      )
    else
      VCenter(
        Label(_("Firewalld is not enabled.\n\nIf you enable firewalld later,\nremember to open the firewall ports for HTTP and HTTPS."))
      )
    end
  end

  def run
    read_config
    result = super
    write_config if result == :next
    result
  end

  # Widget for opening HTTP & HTTPS services in the firewall
  class FirewallWidget < CWM::CustomWidget
    attr_accessor :cwm_interfaces

    def initialize
      textdomain 'rmt'

      @cwm_interfaces = Yast::CWMFirewallInterfaces.CreateOpenFirewallWidget(
        'services'        => services,
        'display_details' => true,
        'open_firewall_checkbox' => _('Open Ports for HTTP and HTTPS in Firewall')
      )
    end

    def init
      Yast::CWMFirewallInterfaces.OpenFirewallInit(@cwm_interfaces, '')
    end

    def contents
      @cwm_interfaces['custom_widget']
    end

    def help
      _('For RMT to work properly, firewall ports for HTTP and HTTPS need to be opened.')
    end

    def handle(event)
      Yast::CWMFirewallInterfaces.OpenFirewallHandle(@cwm_interfaces, '', event)
    end

    def store
      Yast::CWMFirewallInterfaces.StoreAllowedInterfaces(services)
    end

    def validate
      open? || Yast::Popup.AnyQuestion(
        _('Firewall ports not opened'),
        _('Do you want to continue without opening the firewall ports for RMT?'),
        _('Ignore and continue'),
        _('Go back'),
        :focus_no
      )
    end

    def services
      ['http', 'https']
    end

    def status_label
      Yast::CWMFirewallInterfaces.current_firewall_status_label
    end

    private

    def open?
      Yast::UI.QueryWidget(Id('_cwm_open_firewall'), :Value)
    end

    class Yast::CWMFirewallInterfacesClass
      # add public method to access private information
      def current_firewall_status_label
        firewall_status_label(current_firewall_status)
      end
    end
  end

  private

  # This is not required but it is more elegant than using the complete call every time
  def firewalld
    Y2Firewall::Firewalld.instance
  end

  def read_config
    return if !(firewalld.installed? && firewalld.enabled?) || firewalld.read?
    Yast::Popup.Feedback(_('Please wait'), _('Reading firewall settings ...')) do
      firewalld.read
    end
  end

  def write_config
    return unless firewalld.modified?
    Yast::Popup.Feedback(_('Please wait'), _('Writing firewall settings ...')) do
      firewalld.write
    end
  end
end
