class AuthenticationController < ApplicationController
  before_action :authorize_request, except: :login
  JWT_EXPIRE_HOURS = 24.hours

  def login
    return invalid_credentials unless user_authenticated?

    payload = { user_id: 1, user_login: Settings.default_login }
    auth_jwt = JsonWebToken.encode(payload)
    render json: { token: auth_jwt }, status: :ok
  end

  def logout
    cookies.delete :refresh_token
    head :ok
  end

  private

  def item_params
    params.permit(:username, :password)
  end

  def user_authenticated?
    item_params[:username] == Settings.default_login && item_params[:password] == Settings.default_password
  end

  def refresh_token
    return invalid_refresh_cookie if cookies[:refresh_token].nil?

    refresh_cookie = nil
    begin
      refresh_cookie = decrypt_cookie(cookies[:refresh_token])
    rescue => e
      render json: { error: e.message }, status: 400 and return
    end

    decoded_token = JSON.parse(refresh_cookie)
    user = User.find_by(id: decoded_token["id"])
    render json: { error: "user not found" }, status: 404 and return if user.nil?

    expires_at = decoded_token["expires_at"]
    render json: { error: "token expired" }, status: 477 and return if expires_at.nil? || expires_at < Time.zone.now

    auth_jwt = JsonWebToken.encode(user_id: 1)
    token_data = { id: user.id, expires_at: Time.zone.now + REFRESH_COOKIE_INTERNAL_EXPIRE_HOURS, http_only: true }
    cookies[:refresh_token] = { value: @helper.encrypt_cookie(token_data.to_json), expires: Time.zone.now + REFRESH_COOKIE_EXPIRE_HOURS }
    render json: { auth_jwt: auth_jwt }, status: 200
  end
end
