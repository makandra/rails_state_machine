module RailsStateMachine
  class StateMachine
    def initialize(model, state_attribute)
      @model = model
      @state_attribute = state_attribute
      @states_by_name = {}
      @events_by_name = {}
      build_model_module
    end

    def configure(&block)
      instance_eval(&block)

      define_state_methods
      define_state_constants
      register_initial_state

      define_event_methods
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

      @events_by_name[name] = event
    end

    def model_constant(name, value)
      @model.const_set(name, value)
    end

    def build_model_module
      # Using a state machine defines several methods on the model.
      # The model should be able to re-define them and `super` into the original method, if necessary.
      # For that, we use a module to store all methods. The module is loaded into the model class.
      @model_module = Module.new
      @model.include(@model_module)
    end

    def model_module_eval(&block)
      @model_module.module_eval(&block)
    end

    def define_state_methods
      state_attribute = @state_attribute
      state_names.each do |state_name|
        model_module_eval do
          define_method "#{state_name}?" do
            state_machine_state_manager(state_attribute).state == state_name.to_s
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
      state_attribute = @state_attribute
      initial_state_name = states.detect(&:initial?)&.name
      return unless initial_state_name

      @model.after_initialize do
        manager = state_machine_state_manager(state_attribute)
        if new_record? && !manager.state
          manager.state = initial_state_name
        end
      end
    end

    def define_event_methods
      state_attribute = @state_attribute
      event_names.each do |event_name, event|
        model_module_eval do
          define_method "#{event_name}" do |**attributes|
            prepare_state_event_change(attributes.merge("#{state_attribute}_event": event_name))
            save
          end

          define_method "#{event_name}!" do |**attributes|
            prepare_state_event_change(attributes.merge("#{state_attribute}_event": event_name))
            save!
          end

          define_method "may_#{event_name}?" do
            state_machine_state_manager(state_attribute).transition_allowed_for?(event_name)
          end
        end
      end
    end

    def define_model_methods
      state_attribute = @state_attribute

      model_module_eval do
        define_method :"#{state_attribute}_event=" do |event_name|
          state_machine_state_manager(state_attribute).transition_to(event_name)
        end

        define_method :"#{state_attribute}_event" do
          state_machine_state_manager(state_attribute).next_event&.name
        end
      end
    end
  end
end
