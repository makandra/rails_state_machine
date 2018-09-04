module RailsStateMachine
  class StateMachine
    def initialize(model)
      @model = model

      model_constant('StateMachineMethods', Module.new)
      @model.include(@model::StateMachineMethods)

      @states_by_name = {}
      @events_by_name = {}
    end

    def configure(&block)
      instance_eval(&block)

      define_state_methods
      define_state_constants
      register_initial_state

      define_event_methods

      register_callbacks
      register_validations
      register_state_machine

      define_model_methods
    end

    def states
      @states_by_name.values
    end

    def state_names
      @states_by_name.keys
    end

    def events
      @events_by_name.values
    end

    def event_names
      @events_by_name.keys
    end

    def find_event(name)
      @events_by_name.fetch(name.to_sym)
    end

    def has_state?(name)
      @states_by_name.key?(name.to_sym)
    end

    private

    def state(name, **options)
      @states_by_name[name] = State.new(name, options)
    end

    def event(name, &block)
      event = Event.new(name, self)
      event.configure(&block)

      model_methods do
        define_method "#{event.name}" do |**attributes|
          prepare_state_event_change(attributes.merge(state_event: event.name))
          save
        end

        define_method "#{event.name}!" do |**attributes|
          prepare_state_event_change(attributes.merge(state_event: event.name))
          save!
        end
      end

      @events_by_name[name] = event
    end

    def model_constant(name, value)
      @model.const_set(name, value)
    end

    def model_methods(&block)
      # Using a state machine defines several methods on the model.
      # The model should be able to re-define them and `super` into the original method, if necessary.
      # For that, we use a module to store all methods. The module is loaded into the model class.
      @model::StateMachineMethods.module_eval(&block)
    end

    def define_state_methods
      state_names.each do |state_name|
        model_methods do
          define_method "#{state_name}?" do
            self.state.to_s == state_name.to_s
          end
        end
      end
    end

    def define_state_constants
      state_names.each do |state_name|
        model_constant("STATE_#{state_name.upcase}", state_name)
      end
    end

    def register_initial_state
      initial_state = states.detect(&:initial?)
      return unless initial_state

      @model.after_initialize do
        self.state ||= initial_state.name if new_record?
      end
    end

    def define_event_methods
      event_names.each do |event_name, event|
        model_methods do
          define_method "may_#{event_name}?" do
            state_machine.find_event(event_name).allowed_from?(source_state)
          end
        end
      end
    end

    def register_callbacks
      @model.class_eval do
        before_validation :run_state_event_before_validation
        before_save :register_state_events_for_callbacks
        before_save { flush_state_event_callbacks(:before_save) }
        after_save { flush_state_event_callbacks(:after_save) }
        after_commit { flush_state_event_callbacks(:after_commit) }
      end
    end

    def register_validations
      @model.class_eval do
        after_validation :revert_state, if: -> { errors.any? }
      end
    end

    def register_state_machine
      @model.class_eval do
        cattr_accessor :state_machine
        delegate :state_machine, to: :class
      end

      @model.state_machine = self
    end

    def define_model_methods
      model_methods do
        def state_event=(event_name)
          @next_state_machine_event = state_machine.find_event(event_name)
          @state_before_state_event = source_state

          # If the event can not transition from source_state, a TransitionNotFoundError will be raised
          self.state = @next_state_machine_event.future_state_name(source_state).to_s
        end

        def state_event
          @next_state_machine_event&.name
        end

        def source_state
          if new_record?
            state
          else
            state_in_database
          end
        end

        private

        def run_state_event_before_validation
          # Since validations may be skipped, we will not register validation callbacks in @state_event_callbacks,
          # but call them explicitly when before_validation callbacks are triggered.
          @next_state_machine_event&.run_before_validation(self)
        end

        def register_state_events_for_callbacks
          @state_event_callbacks ||= {
            before_save: [],
            after_save: [],
            after_commit: []
          }
          @state_event_callbacks[:before_save] << @next_state_machine_event
          @state_event_callbacks[:after_save] << @next_state_machine_event
          @state_event_callbacks[:after_commit] << @next_state_machine_event
          true
        end

        def flush_state_event_callbacks(name)
          while (event = @state_event_callbacks[name].shift)
            event.public_send("run_#{name}", self)
          end
        end

        def unset_next_state_machine_event
          @next_state_machine_event = nil
        end

        def revert_state
          self.state = @state_before_state_event
        end

        def prepare_state_event_change(attributes)
          if saved_changes?
            # After calling `save`, ActiveRecord will flag the changes that it just stored as saved.
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
  end
end
