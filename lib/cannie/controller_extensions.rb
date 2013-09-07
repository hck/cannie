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
      #     #...
      #   end
      #
      def check_permissions(options={})
        after_action(options.slice(:only, :except)) do |controller|
          next if controller.permitted?
          next if options[:if] && !controller.instance_eval(options[:if])
          next if options[:unless] && controller.instance_eval(options[:unless])
          raise CheckPermissionsNotPerformed, 'Action failed the check_permissions because it does not calls permit! method. Add skip_check_permissions to bypass this check.'
        end
      end

      # Skip handling of permissions checking, that was defined by `check_permissions` method
      #
      #   class PostsController < ApplicationController
      #     skip_check_permissions
      #
      #     #...
      #   end
      def skip_check_permissions(*args)
        before_action(*args) do |controller|
          controller.instance_variable_set(:@_permitted, true)
        end
      end
    end

    # Checks whether passed action is permitted for passed subject
    #
    #   can? :read, on: @posts
    #
    # or
    #
    #   can? :read, on: Post
    #
    # @param [Symbol] action
    # @param [Object] subject
    # @return [Boolean] result of checking permission
    #
    def can?(action, on: nil)
      raise Cannie::SubjectNotSetError, 'Subject should be specified' unless on
      current_permissions.can?(action, on: on)
    end

    # Define permissions, that should be checked inside controller's action
    #
    #  def index
    #    permit! :read, on: Post
    #    @posts = Post.all
    #  end
    #
    # @param [Symbol] action
    # @param [Object] subject
    #
    def permit!(action, on: nil)
      raise Cannie::SubjectNotSetError, 'Subject should be specified' unless on
      current_permissions.permit!(action, on: on)
      @_permitted = true
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