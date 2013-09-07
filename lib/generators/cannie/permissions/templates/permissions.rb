class Permissions
  include Cannie::Permissions

  def initialize(user)
    # Define abilities for the passed user:
    #
    #   user ||= User.new
    #   if user.admin?
    #     allow :manage, on: Model
    #   else
    #     can :read, on: Model
    #   end
    #
  end
end