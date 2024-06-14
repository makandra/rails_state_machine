module RailsStateMachine
  class StateManager
    attr_accessor :next_event, :state_before_state_event
    attr_reader :state_attribute

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
      if @next_event
        self.state = @state_before_state_event
        self.state_event = @next_event.name
      end
    end

    def source_state
      if @record.new_record?
        state
      else
        state_in_database
      end
    end

    def state_event
      @record.public_send(:"#{@state_machine.state_attribute}_event")
    end

    def state_event=(value)
      @record.public_send(:"#{@state_machine.state_attribute}_event=", value)
    end

    def transition_allowed_for?(event_name)
      !!@state_machine.find_event(event_name)&.allowed_from?(state)
    end

    def transition_to(event_name)
      if transition_allowed_for?(event_name)
        self.state_before_state_event = source_state
        event = @state_machine.find_event(event_name)
        self.state = event.future_state_name(state).to_s
        self.state_event = nil
        @next_event = event

        true
      else
        false
      end
    end
  end
end
