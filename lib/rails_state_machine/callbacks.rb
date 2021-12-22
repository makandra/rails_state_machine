module RailsStateMachine
  module Callbacks
    class << self
      def included(model)
        register_callbacks(model)
        register_validations(model)
      end

      private

      def register_callbacks(model)
        model.class_eval do
          before_validation :run_state_events_before_validation
          before_save :register_state_events_for_callbacks
          before_save { flush_state_event_callbacks(:before_save) }
          after_save { flush_state_event_callbacks(:after_save) }
          after_commit { flush_state_event_callbacks(:after_commit) }
        end
      end

      def register_validations(model)
        model.class_eval do
          before_validation :add_validation_errors
          after_validation :revert_states, if: -> { errors.any? }
        end
      end
    end

    def run_state_events_before_validation
      # Since validations may be skipped, we will not register validation callbacks in @state_event_callbacks,
      # but call them explicitly when before_validation callbacks are triggered.
      state_machine_state_managers.each do |state_manager|
        state_manager.next_event&.run_before_validation(self)
      end
    end

    def register_state_events_for_callbacks
      @state_event_callbacks ||= {
        before_save: [],
        after_save: [],
        after_commit: []
      }
      state_machine_state_managers.each do |state_manager|
        if (next_event = state_manager.next_event)
          @state_event_callbacks[:before_save] << next_event
          @state_event_callbacks[:after_save] << next_event
          @state_event_callbacks[:after_commit] << next_event
          state_manager.next_event = nil
        end
      end

      true
    end

    def flush_state_event_callbacks(name)
      if @state_event_callbacks
        while (event = @state_event_callbacks[name].shift)
          event.public_send("run_#{name}", self)
        end
      end
    end

    def revert_states
      state_machine_state_managers.each do |state_manager|
        state_manager.revert
      end
    end

    def add_validation_errors
      @validation_errors.each do |attribute, error|
    end
  end
end
