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

    it 'defines state constants with a prefix if a prefix is given' do
      class_with_machine = Class.new(ActiveRecord::Base) do
        include RailsStateMachine::Model
        state_machine(:foo, prefix: 'prefix_foo') do
          state :completed
        end

        state_machine(:bar, prefix: 'prefix_bar') do
          state :completed
        end
      end

      expect(class_with_machine::PREFIX_FOO_STATE_COMPLETED).to be_present
      expect(class_with_machine::PREFIX_BAR_STATE_COMPLETED).to be_present
      expect{ class_with_machine::STATE_COMPLETED }.to raise_error(NameError)
    end

    it 'defines state methods with a prefix if a prefix is given' do
      parcel = parcel_class.new
      expect(parcel).to respond_to(:review_draft?)
      expect(parcel).to respond_to(:review_approved?)
      expect(parcel).to_not respond_to(:draft?)
      expect(parcel).to_not respond_to(:approved?)
    end

    it 'throws an exception if multiple state machines on the same model define the same state name' do
      expect {
        class_with_machine = Class.new(ActiveRecord::Base) do
          include RailsStateMachine::Model
          state_machine(:foo) do
            state :completed
          end

          state_machine(:bar) do
            state :completed
          end
        end
      }.to raise_error(RailsStateMachine::StateMachine::StateAlreadyDefinedError, 'State :completed has already been defined in the :foo state machine. You may use the :prefix option when defining a state machine to avoid that.')
    end

  end

  it 'does not remove already defined state machines if you include the module again afterwards (BUGFIX)' do
    class_with_machine = Class.new(ActiveRecord::Base) do
      include RailsStateMachine::Model
      state_machine(:foo) {}
      include RailsStateMachine::Model
      state_machine(:bar) {}
    end
    expect(class_with_machine.state_machines).to have_key(:foo)
    expect(class_with_machine.state_machines).to have_key(:bar)
    expect(class_with_machine.state_machines[:foo]).to be_a(RailsStateMachine::StateMachine)
    expect(class_with_machine.state_machines[:bar]).to be_a(RailsStateMachine::StateMachine)
  end

end
