module RailsStateMachine
  class StateManager
    attr_accessor :next_event, :state_before_state_event

    def initialize(record, state_machine, state_attribute)
      @record = record
      @state_machine = state_machine
      @state_attribute = state_attribute
    end

    def state
      @record.public_send(@state_attribute)
    end

    def state_in_database
      @record.public_send(:"#{@state_attribute}_in_database").to_s
    end

    def state=(value)
      @record.public_send(:"#{@state_attribute}=", value)
    end

    def revert
      self.state = @state_before_state_event if @next_event
    end

    def source_state
      if @record.new_record?
        state
      else
        state_in_database
      end
    end

    def transition_to(event_name)
      @next_event = @state_machine.find_event(event_name)
      @state_before_state_event = source_state

      # If the event can not transition from source_state, a TransitionNotFoundError will be raised
      self.state = @next_event.future_state_name(source_state).to_s
    end

    def transition_allowed_for?(event_name)
      @state_machine.find_event(event_name).allowed_from?(source_state)
    end
  end
end
