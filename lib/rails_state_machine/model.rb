module RailsStateMachine
  DEFAULT_STATE_ATTRIBUTE = :state

  module Model
    def self.included(base)
      base.class_eval do
        extend ClassMethods

        cattr_accessor :state_machines
        self.state_machines ||= {}

        delegate :state_machine, to: :class
      end
    end

    module ClassMethods
      def state_machine(state_attribute = DEFAULT_STATE_ATTRIBUTE, prefix: '', &block)
        state_machine = state_machines[state_attribute] ||= StateMachine.new(self, state_attribute, prefix: prefix)
        if block
          include(Callbacks) unless self < Callbacks
          state_machine.configure(&block)
        end
        state_machine
      end

      def states(state_attribute = DEFAULT_STATE_ATTRIBUTE)
        state_machine(state_attribute).state_names
      end

      def state_events(state_attribute = DEFAULT_STATE_ATTRIBUTE)
        state_machine(state_attribute).event_names
      end
    end


    private

    def state_machine_state_manager(state_attribute)
      @state_machine_state_managers[state_attribute] ||= StateManager.new(self, state_machine(state_attribute), state_attribute)
    end

    def clear_state_machine_state_managers_cache
      @state_machine_state_managers = {}
    end

    def state_machine_state_managers
      self.state_machines.keys.collect do |state_attribute|
        state_machine_state_manager(state_attribute)
      end
    end

    def prepare_state_event_change(attributes)
      if ActiveRecord::VERSION::STRING < '5.2' && saved_changes?
        # After calling `save`, ActiveRecord 5.1 will flag the changes that it just stored as saved.
        # https://github.com/rails/rails/blob/v5.1.4/activerecord/lib/active_record/attribute_methods/dirty.rb#L33-L46
        #
        # When taking multiple state events (e.g. a second event called inside an `after_save` callback) and thus
        # saving after other changes were just saved, we need to mimic that behavior. Otherwise, ActiveRecord will
        # print deprecation warnings like these:
        #
        #     DEPRECATION WARNING: The behavior of `attribute_was` inside of after callbacks will be changing in the
        #     next version of Rails. The new return value will reflect the behavior of calling the method after
        #     `save` returned (e.g. the opposite of what it returns now). To maintain the current behavior, use
        #     `attribute_before_last_save` instead.
        #
        # These actually originate from ActiveRecord internals which try to determine the changes that should be
        # stored for the second save. It is probably a shortcoming of ActiveRecord 5.1.x that will be fixed, but
        # since the current/previous save was already successful, the right action is to just call `changes_applied`.
        changes_applied
      end
      self.attributes = attributes
    end
  end
end
