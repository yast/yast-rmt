require 'rmt/wizard'

Yast.import 'Wizard'
Yast.import 'Sequencer'

describe RMT::Wizard do
  subject(:wizard) { described_class.new }

  let(:config) { { foo: 'bar' } }

  before do
  end

  it 'runs and goes through the sequence' do
    expect(RMT::Base).to receive(:read_config_file).and_return({})

    expect(Yast::Wizard).to receive(:CreateDialog)
    expect(Yast::Wizard).to receive(:SetTitleIcon)

    expect(wizard).to receive(:step1).and_return(:next)
    expect(wizard).to receive(:step2).and_return(:next)

    expect(Yast::UI).to receive(:CloseDialog)
    wizard.run
  end
end
