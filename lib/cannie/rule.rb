module Cannie
  # Rule class
  class Rule
    attr_reader :action, :subject

    # Initializes new rule.
    #
    # @param [Symbol] action action which should be permitted on subject
    # @param [String, Symbol] subject subject of the rule
    # @param [Hash] options additional options and conditions for the new rule
    # @option options [Proc] :if condition which is checked for a particular Permissions object
    #                            and should be evaluated to true
    # @option options [Proc] :unless condition which is checked for a particular Permissions object
    #                                and should be evaluated to false
    def initialize(action, subject, options = {})
      @action, @subject, @_if, @_unless = action, subject, *options.values_at(:if, :unless)
    end

    # Checks whether rule is applied to permissions passed as an argument.
    #
    # @param [Cannie::Permissions] permissions
    # @return [Boolean]
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
      condition = context.method(condition) if condition.is_a?(Symbol)
      context.instance_exec(&condition)
    end
  end
end
