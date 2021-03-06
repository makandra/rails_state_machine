describe RailsStateMachine::Model do

  subject(:parcel_class) { Parcel }

  describe '.states' do
    it 'returns the list of available states' do
      expect(parcel_class.states).to eq([:empty, :filled, :shipped])
    end
  end

  describe '.state_events' do
    it 'returns the list of available state events' do
      expect(parcel_class.state_events).to eq([:destroy_content, :pack, :pack_and_ship, :ship])
    end
  end

  describe '.state_machine' do
    it 'registers necessary callbacks only once (BUGFIX)' do
      expect(RailsStateMachine::Callbacks).to receive(:included).exactly(:once)
      class_with_machine = Class.new(ActiveRecord::Base) do
        include RailsStateMachine::Model
        state_machine(:foo) {}
        state_machine(:bar) {}
      end
      expect(class_with_machine < RailsStateMachine::Callbacks).to eq true
    end

    it 'shows a proper error message when referring to a missing state' do
      expect {
        class MyClass < ActiveRecord::Base
          include RailsStateMachine::Model
          state_machine do
            state :start
            state :end
            event :finish do
              transitions from: :beginning, to: :end  # should be :start
            end
          end
        end
      } .to raise_error(
        RailsStateMachine::Event::UndefinedStateError,
        "beginning is not a valid state in the state machine of MyClass"
      )
    end

  end

end
