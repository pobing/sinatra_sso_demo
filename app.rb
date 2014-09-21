#encoding: utf-8

require 'json'
require 'sinatra'
require 'net/http'
require 'rest-client'
require 'sinatra/flash'
require 'sinatra/cookies'

enable :sessions
register Sinatra::Flash

configure do
  set :show_exceptions, false
end

get '/sso/auth' do
  login_required

  user = current_user
  username = user['email']
  now = Time.now.to_i.to_s

  token = Digest::MD5.hexdigest(username + now + current_key)

  redirect current_host+"/user/remote?username="+username+"&time="+now+"&token="+token;
end


get '/sso/login' do
  @production = params[:production]
  erb :login
end

post '/sso/login' do
  api_url = "/oauth/access_token"
  default_params = { grant_type: 'password', client_id: 'd793268101c345618e6b', client_secret: 'fca268f25be49bc9cae44a7ab15f88fd58e716fb'}
  data = JSON.generate(default_params.merge!(params))
  begin
    response = RestClient.post(base_url + api_url, data)
    res = JSON.parse(response.body)
    @access_token = res['access_token']
    set_cookie('access_token', res['access_token'])
    redirect "/sso/auth?access_token=#{@access_token}&production=#{params[:production]}"
  rescue Exception => e
    flash[:error] = "用户名或密码错误"
    redirect '/sso/login'
  end
end

get '/sso/logout' do
  flash[:notice] = "您已经成功退出"
  cookies.delete('access_token')
  redirect current_host
end

error do
  flash[:error] = "Oops，请稍后再试"
  redirect '/sso/login'
end

private

  def login_required
    unless current_token
      # flash[:error] = "请登录后再操作"
      redirect '/sso/login?production=' + params[:production].to_s
    end
  end

  def current_user
    begin
      api_url = "/user?access_token=#{current_token}"
      res = RestClient.get(base_url + api_url)
      user = JSON.parse(res)
      user
    rescue Exception => e
      flash[:error] = "请登录后再操作"
      redirect '/sso/login'
    end
  end


  def current_token
    # get access_token from cookies get post header
    @access_token ||= request.cookies["access_token"]
    @access_token ||= params[:access_token]
    @access_token ||= get_header_token
    return nil unless @access_token

    @access_token
  end

  def get_header_token
    keys = %w{HTTP_AUTHORIZATION X-HTTP_AUTHORIZATION X_HTTP_AUTHORIZATION Authorization}
    authorization ||= keys.inject(nil) { |auth, key| auth || request.env[key] }
    authorization.split[1] if authorization and authorization[/^token/i]
  end

  def set_cookie key, value, ttl = 60 * 60
    response.set_cookie(key.to_s, {
      value: value,
      expires: Time.now + ttl,
      domain: cookie_domain, # change your root domain
      path: '/'
    })
  end

  def current_host
    production = params[:production]
    @current_host ||= "http://support.yourdomain.com" if production == 'production1'
    @current_host ||= "http://support.yourdomain.com"  if production == 'production2'
    return nil unless @current_host
    @current_host
  end

  def current_key
    production = params[:production]
    @current_key ||= "cdb61941f367eb6571e69bbc51d0a4" if production == 'production1'
    @current_key ||= "83951084b60a3cb62d58d780f227ac" if production == 'production2'
    return nil unless @current_key
    @current_key
  end

  def base_url
    "your base_url"
  end

  def cookie_domain
    "your root domain"
  end

