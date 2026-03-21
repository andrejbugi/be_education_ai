class ApplicationController < ActionController::API
  include ActionController::Cookies
  include ActiveStorage::SetCurrent
end
