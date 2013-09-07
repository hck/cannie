module Cannie
  class Rule
    attr_reader :actions, :subject, :condition

    def initialize(*actions, subject, &block)
      @actions = actions
      @subject = subject
      @condition = block
    end

    def permits?(*args)
      if condition
        !!condition.call(*args)
      else
        true
      end
    end
  end
end