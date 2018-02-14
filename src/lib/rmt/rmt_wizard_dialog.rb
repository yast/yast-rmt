module Yast
  class RMTWizardDialog < Client
    include Yast::UIShortcuts

    def run
      Yast.import "UI"
      Yast.import "Wizard"
      Yast.import "Sequencer"

      textdomain "rmt"

      Wizard.CreateDialog()
      run_wizard
      UI.CloseDialog()
    end
  end

  def step1
    contents = HVSquash(
      VBox(
        VSpacing(1)
      )
    )

    Wizard.SetContents(
        _("RMT configuration step 1"),
        contents,
        "There's no help! You are on your own!",
        true,
        true
    )

    ret = nil
    while true
      ret = UI.UserInput
      if ret == :abort || ret == :cancel
        break
      elsif ret == :next
        break
      elsif ret == :back
        Yast::Popup.Message("THERE'S NO GOING BACK!!!")
      end
    end

    deep_copy(ret)
  end

  def step2
    contents = HVSquash(
      VBox(
        VSpacing(1)
      )
    )

    Wizard.SetNextButton(:next, Label.OKButton)
    Wizard.SetContents(
        _("RMT configuration step 2"),
        contents,
        "There's no help! You are on your own!",
        true,
        true
    )

    ret = nil
    while true
      ret = UI.UserInput
      if ret == :abort || ret == :cancel
        break
      elsif ret == :next
        Yast::Popup.Message("Bye-bye!")
        break
      elsif ret == :back
        break
      end
    end

    deep_copy(ret)
  end

  def run_wizard
    aliases = {
        "step1" => lambda { step1() },
        "step2" => lambda { step2() }
    }

    sequence = {
        "ws_start" => "step1",
        "step1"   => { :abort => :abort, :next => "step2" },
        "step2"   => { :abort => :abort, :next => :next }
    }

    Wizard.SetTitleIcon("yast-rmt")
    Wizard.DisableBackButton
    Wizard.SetAbortButton(:abort, Label.CancelButton)
    Wizard.SetNextButton(:next, Label.NextButton)

    ret = Sequencer.Run(aliases, sequence)

    Wizard.RestoreNextButton
    Wizard.RestoreAbortButton
    Wizard.RestoreBackButton

    deep_copy(ret)
  end
end