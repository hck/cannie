module Cannie
  module Permissions
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # Defines a namespace for permissions and defines the permissions inside the namespace.
      #
      # @param [Symbol, String] name name of the namespace
      # @param [Proc] block block to define permissions inside the namespace
      def namespace(name, &block)
        orig_scope = @scope
        @scope     = [orig_scope, name].compact.join('/')
        instance_exec(&block)
      ensure
        @scope = orig_scope
      end

      # Defines a controller for permissions and defines the permissions inside the controller.
      #
      # @param [Symbol, String] name name of the controller
      # @param [Proc] block block to define permissions inside the controller
      def controller(name, &block)
        @controller = name
        instance_exec(&block)
      ensure
        @controller = nil
      end

      # Defines the rules for specified action.
      #
      # @param [String, Symbol, Array<String,Symbol>] action name of the action
      # @param [Hash] options additional options
      # @option options [Symbol, String] on name of the controller or list of controller names for which current rule should be applies
      # @option options [Proc] if current rule should be applied for the action when the `if` block is evaluated to true
      # @option options [Proc] unless current rule should be applied for the action when the `unless` block is evaluated to false
      def allow(action, options = {})
        opts = options.slice(:if, :unless)
        subjects = Array(@controller || options[:on]).map { |v| subject(v) }

        Array(action).each do |action_name|
          subjects.each do |subj|
            rules << Rule.new(action_name, subj, opts)
          end
        end
      end

      # Returns list of currently defined access rules.
      #
      # @return [Array<Rule>]
      def rules
        @rules ||= []
      end

      private

      def subject(name)
        (name == :all && name) || [@scope, name].compact.join('/')
      end
    end

    attr_reader :user

    # Initializes instance of Permissions class for given user
    #
    # @param [Object] user a user, whose permissions will be checked
    # @return [Permissions] new instance of Permissions class
    def initialize(user)
      @user = user
    end

    # Checks if at least one rule for specified action add subject is present.
    #
    # @param [Symbol] action
    # @param [String, Symbol] subject
    # @return [Boolean]
    def can?(action, subject)
      rules_for(action, subject).present?
    end

    # Raises error Cannie::ActionForbidden if there is no rules for specified action and subject.
    #
    # @param [Symbol] action
    # @param [String, Symbol] subject
    def permit!(action, subject)
      raise Cannie::ActionForbidden unless can?(action, subject)
    end

    private

    def rules
      @rules ||= self.class.rules.select { |rule| rule.applies_to?(self) }
    end

    def rules_for(action, subject)
      subject = subject.respond_to?(:controller_path) ? subject.controller_path : subject.to_s

      rules.select do |rule|
        rule.action.to_sym == action.to_sym && (rule.subject == :all || rule.subject == subject)
      end
    end
  end
end
