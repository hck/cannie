class Permissions
  include Cannie::Permissions

  # namespace :admin do
  #   allow :index, on: :users, if: ->{ user.admin? }
  #   allow :show, on: :users, if: :admin?
  #   allow :new, on: :users, unless: :member?
  #
  #   controller :posts do
  #     allow :index
  #   end
  # end
  #
  # controller :users do
  #   allow [:sign_in, :sign_up]
  # end
  #
  # allow [:index, :show, :new, :create, :edit, :update, :destroy], on: [:posts, :comments]
end