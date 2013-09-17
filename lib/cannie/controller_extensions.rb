module Cannie
  module ControllerExtensions
    extend ActiveSupport::Concern

    included do
      extend ClassMethods
      helper_method :can?, :current_permissions
    end

    RESOURCE_ACTIONS = {
      index:   :list,
      show:    :read,
      new:     :create,
      create:  :create,
      edit:    :update,
      update:  :update,
      destroy: :destroy
    }

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
          next if options[:if] && !controller.instance_eval(&options[:if])
          next if options[:unless] && controller.instance_eval(&options[:unless])
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

      # Permit resource actions [index, show, new, create, edit, update, destroy] in controller
      #
      #
      def permit_resource_actions(options={})
        after_action(options.slice(:only, :except)) do |controller|
          begin
            next if controller.permitted?
            next if options[:if] && !controller.instance_eval(&options[:if])
            next if options[:unless] && controller.instance_eval(&options[:unless])
            controller.permit! RESOURCE_ACTIONS.with_indifferent_access[action_name], on: controller.subject_for_action
          rescue Cannie::ActionForbidden
            self.response_body = nil
            raise
          end
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

    def subject_for_action
      return unless RESOURCE_ACTIONS.with_indifferent_access.keys.include?(action_name)
      entry_name = controller_name.classify.demodulize.downcase
      collection_name = entry_name.pluralize
      variable_name = action_name == 'index' ? collection_name : entry_name
      instance_variable_get(:"@#{variable_name}")
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