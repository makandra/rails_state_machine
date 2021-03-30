module RailsStateMachine
  class Event
    Transition = Struct.new(:from, :to)

    UndefinedStateError = Class.new(StandardError)
    TransitionNotFoundError = Class.new(StandardError)
    ExistingTransitionError = Class.new(StandardError)

    attr_reader :name

    def initialize(name, state_machine)
      @name = name
      @state_machine = state_machine

      @before_validation = []
      @before_save = []
      @after_save = []
      @after_commit = []

      @transitions_by_state_name = {}
    end

    def configure(&block)
      instance_eval(&block)
    end

    def transitions(**options)
      if options.present?
        add_transitions(**options)
      else
        @transitions_by_state_name.values
      end
    end

    def run_before_validation(record)
      @before_validation.each do |block|
        record.instance_eval(&block)
      end
    end

    def run_before_save(record)
      @before_save.each do |block|
        record.instance_eval(&block)
      end
    end

    def run_after_save(record)
      @after_save.each do |block|
        record.instance_eval(&block)
      end
    end

    def run_after_commit(record)
      @after_commit.each do |block|
        record.instance_eval(&block)
      end
    end

    def find_transition_from(state_name)
      @transitions_by_state_name[state_name&.to_sym] || raise(TransitionNotFoundError, "#{name} does not transition from #{state_name}; defined are #{transitions}")
    end

    def allowed_from?(state_name)
      @transitions_by_state_name.key?(state_name&.to_sym)
    end

    def future_state_name(state_name)
      find_transition_from(state_name).to
    end

    private

    def add_transitions(from:, to:)
      froms = Array(from)
      froms.each { |from| add_transition(from, to) }
    end

    def add_transition(from, to)
      if !@state_machine.has_state?(from)
        raise UndefinedStateError, "#{from} is not a valid state in the state machine of #{@state_machine.model}"
      elsif allowed_from?(from)
        raise ExistingTransitionError, "#{name} already defines a transition from #{from} (to #{future_state_name(from)})"
      else
        @transitions_by_state_name[from] = Transition.new(from, to)
      end
    end

    def before_validation(&block)
      @before_validation << block
    end

    def before_save(&block)
      @before_save << block
    end

    def after_save(&block)
      @after_save << block
    end

    def after_commit(&block)
      @after_commit << block
    end
  end
end
