require 'sinatra/base'
require 'sinatra/reloader'
require_relative 'lib/database_connection'
require_relative 'lib/account_repository'

if ENV['ENV'] == 'test'
  DatabaseConnection.connect("makersbnb_test")
else
  DatabaseConnection.connect("makersbnb")
end

class Application < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end

  get '/' do
    @error_message = ''
    return erb(:index)
  end


  post '/' do
    if params[:password_confirmation] != params[:password] 
      @error_message = 'Passwords do not match. Please re-submit.'
      return erb(:index)
    end 

    repo = AccountRepository.new
    repo.all.each do |account|
      if account.email == params[:email]
        @error_message = 'Email already registered. Please re-submit or sign-in.'
        return erb(:index)
      end 
    end 
    
    new_account = Account.new
    
    new_account.email = params[:email]
    new_account.password = params[:password]
    @name = params[:name]
    new_account.name = @name 
    new_account.dob = params[:dob]

    repo.create(new_account)

    return erb(:signup_confirmation)
  end
end
