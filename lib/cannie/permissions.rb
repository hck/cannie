module Cannie
  # This module provides possibility to define permissions using "allow" method
  #
  #   class Permissions
  #     include Cannie::Permissions
  #
  #     def initialize(user)
  #       allow :read, on: Model
  #       allow :manage, on: Model do |*entries|
  #         entries.all?{|v| v.user == user}
  #       end
  #     end
  #   end
  #
  module Permissions
    # Define rules for further permissions checking
    #
    #   allow :read, on: Model
    #
    # @param actions
    # @param on
    # @return array of rules
    def allow(*actions, on: nil, &block)
      rules << Rule.new(*actions, on, &block)
    end

    # Check permission by given action on subject, that is passed in 'on' parameter
    #
    #   can? :read, on: Model
    #
    # or
    #
    #   can? :read, on: models
    #
    # @param action
    # @param on
    # @return result of permissions check
    #
    def can?(action, on: nil)
      rules = rules_for(action, on)
      rules.present? && rules.all? do |rule|
        rule.permits?(*on)
      end
    end

    # Permit access for action on a subject
    #
    #   permit! :read, on: Model
    #
    # or
    #
    #   permit! :manage, on: models
    #
    # @param [Symbol] Action
    #
    def permit!(action, on: nil)
      raise Cannie::ActionForbidden unless can?(action, on: on)
    end

    private
    def rules
      @rules ||= []
    end

    def rules_for(action, subject)
      klass = subject.is_a?(Class) ? subject : subject.class
      rules.select do |r|
        r.actions.include?(action) && (subject == :all || klass <= r.subject)
      end
    end
  end
end