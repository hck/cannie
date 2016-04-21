module Cannie
  # Adds permission checking methods and filters to ActionController::Base
  module ControllerExtensions
    def self.included(base)
      base.extend ClassMethods
      base.helper_method :can?, :current_permissions
    end

    # Class methods available in the class scope when the ControllerExtensions module is included
    module ClassMethods
      # Adds before action to check permissions before processing the controller's action.
      #
      #   class PostsController < ApplicationController
      #     check_permissions
      #
      #     # ...
      #   end
      #
      # @param [Hash] options
      # @option options [Proc] if permissions are checked when this block is evaluated to true
      # @option options [Proc] unless permissions are checked when this block is evaluated to false
      # @option options [Array, Symbol] only action or list of actions for which permissions should be checked
      # @option options [Array, Symbol] except action or list of actions for which permissions should not be checked
      def check_permissions(options = {})
        condition_if, condition_unless = options.values_at(:if, :unless)
        before_action(options.slice(:only, :except)) do |controller|
          next if controller.permitted?
          next if condition_if && !controller.instance_eval(&condition_if)
          next if condition_unless && controller.instance_eval(&condition_unless)
          current_permissions.permit!(controller.action_name, controller)
        end
      end

      # Skip handling of permissions checking, that was defined by `check_permissions` method.
      #
      #   class PostsController < ApplicationController
      #     skip_check_permissions
      #
      #     # ...
      #   end
      def skip_check_permissions(*args)
        prepend_before_action(*args) do |controller|
          controller.instance_variable_set(:@_permitted, true)
        end
      end
    end

    # Checks whether passed action is permitted for passed subject.
    #
    #   can? :index, on: :entries
    #
    # or
    #
    #   can? :index, on: EntriesController
    #
    # or
    #
    #   can? :index, on: 'admin/entries'
    #
    # @param [Symbol] action
    # @param [Object] controller class or controller_path as a string or symbol
    # @return [Boolean] result of checking permission
    def can?(action, on: nil)
      raise Cannie::SubjectNotSetError, 'Subject should be specified' unless on
      current_permissions.can?(action, on)
    end

    # Returns value of permitted flag, indicating whether permissions check is skipped or not.
    #
    # @return [Boolean]
    def permitted?
      !!@_permitted
    end

    # Creates instance of Permissions class for current user if it was not inited yet.
    #
    # @returns [Permissions]
    def current_permissions
      @current_permissions ||= ::Permissions.new(current_user)
    end
  end
end

if defined? ActionController::Base
  ActionController::Base.class_exec do
    include Cannie::ControllerExtensions
  end
end
