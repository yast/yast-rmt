class RMT::MariaDB::NewRootPasswordDialog < RMT::Base
  def run
    ret = nil

    UI.OpenDialog(
        VBox(
            VSpacing(1),
            Heading(_('Setting database root password')),
            VSpacing(1),
            HBox(
                HSpacing(2),
                VBox(
                    Label(
                        _(
                            "The current MariaDB root password is empty.\n" \
                    'Setting a root password is required for security reasons.'
                        )
                    ),
                    VSpacing(1),
                    MinWidth(15, Password(Id(:new_root_password_1), _('New MariaDB root &Password'))),
                    MinWidth(15, Password(Id(:new_root_password_2), _('New Password &Again')))
                ),
                HSpacing(2)
            ),
            VSpacing(1),
            HBox(
                PushButton(Id(:cancel), Opt(:key_F9), Label.CancelButton),
                HSpacing(2),
                PushButton(Id(:ok), Opt(:default, :key_F10), Label.OKButton)
            ),
            VSpacing(1)
        )
    )

    UI.SetFocus(Id(:new_root_password_1))

    loop do
      user_ret = UI.UserInput

      if user_ret == :cancel
        ret = nil
        break
      elsif user_ret == :ok
        pass_1 = Convert.to_string(UI.QueryWidget(Id(:new_root_password_1), :Value))
        pass_2 = Convert.to_string(UI.QueryWidget(Id(:new_root_password_2), :Value))

        if pass_1.nil? || pass_1 == ''
          UI.SetFocus(Id(:new_root_password_1))
          Report.Error(_('Password must not be blank.'))
          next
        elsif pass_1 != pass_2
          UI.SetFocus(Id(:new_root_password_2))
          Report.Error(_('The first and the second password do not match.'))
          next
        end

        ret = pass_1
        break
      end
    end

    UI.CloseDialog

    ret
  end

  def set_root_password(new_root_password, hostname)
    run_command(
        "echo 'SET PASSWORD FOR root@%1=PASSWORD(\"%2\");' | mysql -u root 2>/dev/null",
        hostname,
        new_root_password
    ) == 0
  end
end