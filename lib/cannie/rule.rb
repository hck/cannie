module Cannie
  class Rule
    attr_reader :action, :subject

    def initialize(action, subject, options={})
      @action, @subject, @_if, @_unless = action, subject, *options.values_at(:if, :unless)
    end

    def applies_to?(permissions)
      if?(permissions) && unless?(permissions)
    end

    private
    attr_reader :_if, :_unless

    def if?(permissions)
      _if ? exec_condition(_if, permissions) : true
    end

    def unless?(permissions)
      _unless ? !exec_condition(_unless, permissions) : true
    end

    def exec_condition(condition, context)
      if condition.is_a?(Symbol)
        context.instance_eval(&condition)
      else
        context.instance_exec(&condition)
      end
    end
  end
end
