module Cannie
  class SubjectNotSetError < StandardError; end

  class CheckPermissionsNotPerformed < StandardError; end

  class ActionForbidden < StandardError; end
end