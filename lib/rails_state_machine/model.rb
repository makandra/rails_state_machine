module RailsStateMachine
  module Model
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def state_machine(&block)
        StateMachine.new(self).configure(&block)
      end

      def states
        state_machine.state_names
      end

      def state_events
        state_machine.event_names
      end
    end
  end
end
