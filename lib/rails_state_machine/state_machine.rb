module RailsStateMachine
  class StateMachine

    StateAlreadyDefinedError = Class.new(StandardError)

    def initialize(model, state_attribute, prefix: '')
      @model = model
      @state_attribute = state_attribute
      @prefix = prefix
      @prefix_for_constant_definition = "#{@prefix.upcase}_" if @prefix.present?
      @prefix_for_method_definition = "#{@prefix.downcase}_" if @prefix.present?
      @states_by_name = {}
      @events_by_name = {}
      build_model_module
    end

    attr_reader :model, :prefix, :prefix_for_constant_definition, :prefix_for_method_definition, :state_attribute

    def configure(&block)
      instance_eval(&block)

      check_if_states_already_defined

      define_state_methods
      define_state_constants
      register_initial_state

      define_event_methods
      define_attributes
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
      @events_by_name[name.to_sym]
    end

    def has_state?(name)
      @states_by_name.key?(name.to_sym)
    end

    private

    def state(name, **options)
      @states_by_name[name] = State.new(name, **options)
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

    def check_if_states_already_defined
      @states_by_name.each do |state_name, _|
        other_state_machines.each do |state_machine|
          if state_machine.has_state?(state_name) && state_machine.prefix == prefix
            raise StateAlreadyDefinedError, "State #{state_name.inspect} has already been defined in the #{state_machine.state_attribute.inspect} state machine. You may use the :prefix option when defining a state machine to avoid that."
          end
        end
      end
    end

    def other_state_machines
      model.state_machines.except(@state_attribute).values
    end

    def define_state_methods
      state_attribute = @state_attribute
      prefix = prefix_for_method_definition
      state_names.each do |state_name|
        model_module_eval do
          define_method "#{prefix}#{state_name}?" do
            state_machine_state_manager(state_attribute).state == state_name.to_s
          end
        end
      end
    end

    def define_state_constants
      state_names.each do |state_name|
        model_constant("#{@prefix_for_constant_definition}STATE_#{state_name.upcase}", state_name)
      end
    end

    def register_initial_state
      state_attribute = @state_attribute
      initial_state_name = states.detect(&:initial?)&.name
      return unless initial_state_name

      @model.after_initialize do
        clear_state_machine_state_managers_cache
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

    def define_attributes
      state_attribute = @state_attribute

      @model.instance_eval do
        attribute :"#{state_attribute}_event", :string
      end
    end
  end
end
