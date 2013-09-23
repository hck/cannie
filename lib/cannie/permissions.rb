module Cannie
  module Permissions
    extend ActiveSupport::Concern

    included do
      extend ClassMethods
    end

    module ClassMethods
      def namespace(name, &block)
        orig_scope = @scope
        @scope     = [orig_scope, name].compact.join('/')
        instance_exec(&block)
      ensure
        @scope = orig_scope
      end

      def controller(name, &block)
        @controller = name
        instance_exec(&block)
      ensure
        @controller = nil
      end

      def allow(action, options={})
        opts = options.slice(:if, :unless)
        subjects = Array(@controller || options[:on]).map { |v| subject(v) }

        Array(action).each do |action_name|
          subjects.each do |subj|
            rules << Rule.new(action_name, subj, opts)
          end
        end
      end

      def rules
        @rules ||= []
      end

      private
      def subject(name)
        (name == :all && name) || ([@scope, name].compact.join('/'))
      end
    end

    attr_reader :user

    def initialize(user)
      @user = user
    end

    def can?(action, subject)
      rules_for(action, subject).present?
    end

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