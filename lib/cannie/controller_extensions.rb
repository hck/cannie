module Cannie
  module ControllerExtensions
    extend ActiveSupport::Concern

    included do
      extend ClassMethods
      helper_method :can?, :current_permissions
    end

    module ClassMethods
      # Method is used to be sure, that permissions checking is handled for each action inside controller.
      #
      #   class PostsController < ApplicationController
      #     check_permissions
      #
      #     # ...
      #   end
      #
      def check_permissions(options={})
        _if, _unless = options.values_at(:if, :unless)
        before_action(options.slice(:only, :except)) do |controller|
          next if controller.permitted?
          next if _if && !controller.instance_eval(&_if)
          next if _unless && controller.instance_eval(&_unless)
          current_permissions.permit!(controller.action_name, controller)
        end
      end

      # Skip handling of permissions checking, that was defined by `check_permissions` method
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

    # Checks whether passed action is permitted for passed subject
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
    #
    def can?(action, on: nil)
      raise Cannie::SubjectNotSetError, 'Subject should be specified' unless on
      current_permissions.can?(action, on)
    end

    def permitted?
      !!@_permitted
    end

    def current_permissions
      @current_permissions ||= ::Permissions.new(current_user)
    end

    private
    attr_reader :_permitted
  end
end

if defined? ActionController::Base
  ActionController::Base.class_eval do
    include Cannie::ControllerExtensions
  end
end