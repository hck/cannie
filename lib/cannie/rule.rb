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
      _if ? permissions.instance_exec(&_if) : true
    end

    def unless?(permissions)
      _unless ? !permissions.instance_exec(&_unless) : true
    end
  end
end