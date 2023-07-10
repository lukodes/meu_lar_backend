class LoginController < ApplicationController
  before_action :require_login, only: [:logout]
  JWT_EXPIRE_HOURS = 24.hours

  def login
    return incorrect_credentials unless params[:username] == Settings.default_login && params[:password] == Settings.default_password

    token = generate_jwt
    render json: { token: token }
  end

  def logout
    cookies.delete :refresh_token
    head :ok
  end

  private

  def item_params
    params.permit(:login, :password)
  end

  def generate_jwt(user)
    exp = (Time.zone.now() + JWT_EXPIRE_HOURS).to_i
    payload = { id: 1, exp: exp, name: 'admin', login: 'admin' }
    JWT.encode payload, Settings.faye_secret, 'HS256'
  end

  def incorrect_credentials
    render json: { error: 'Incorrect credentials' }, status: 401
  end

  def invalid_refresh_cookie
    render json: { error: 'Invalid refresh cookie' }, status: 401
  end

  def refresh_token
    return invalid_refresh_cookie if cookies[:refresh_token].nil?

    refresh_cookie = nil
    begin
      refresh_cookie = decrypt_cookie(cookies[:refresh_token])
    rescue => e
      render json: { errors: e.message }, status: 400 and return
    end

    decoded_token = JSON.parse(refresh_cookie)
    user = User.find_by(id: decoded_token["id"])
    render json: { errors: "user_not_found" }, status: 404 and return if user.nil?

    expires_at = decoded_token["expires_at"]
    render json: { errors: "token expired" }, status: 477 and return if expires_at.nil? || expires_at < Time.zone.now

    auth_jwt = generate_jwt(user)
    token_data = { id: user.id, expires_at: Time.zone.now + REFRESH_COOKIE_INTERNAL_EXPIRE_HOURS, http_only: true }
    cookies[:refresh_token] = { value: @helper.encrypt_cookie(token_data.to_json), expires: Time.zone.now + REFRESH_COOKIE_EXPIRE_HOURS }
    render json: { auth_jwt: auth_jwt }, status: 200
  end

  def decrypt_cookie(data)
    secret_key_base = Settings.refresh_cookie_password
    len = ActiveSupport::MessageEncryptor.key_len
    salt = Settings.cookie_salt
    key = ActiveSupport::KeyGenerator.new(secret_key_base).generate_key(salt, len)
    crypt = ActiveSupport::MessageEncryptor.new(key)
    crypt.decrypt_and_verify(data)
  end
end
