module RailsStateMachine
  class State
    attr_reader :name, :options

    def initialize(name, **options)
      @name = name
      @options = options
    end

    def initial?
      !!options[:initial]
    end
  end
end
