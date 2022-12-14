require 'sinatra/base'
require 'sinatra/reloader'
require_relative 'lib/space_repository'
require_relative 'lib/database_connection'
require_relative 'lib/account_repository'
require_relative 'lib/booking_repository'

if ENV['ENV'] == 'test'
  DatabaseConnection.connect("makersbnb_test")
else
  DatabaseConnection.connect("makersbnb")
end

class Application < Sinatra::Base
  enable :sessions
  configure :development do
    register Sinatra::Reloader
    also_reload 'lib/space_repository'
  end

  get '/' do
    @error_message = ''
    return erb(:index)
  end

  get '/spaces' do
    @user_id = session[:user_id]
    repo = SpaceRepository.new
    @spaces = repo.all
    return erb(:spaces)

  end

  get '/spaces/new' do
    return erb(:new_space)
  end

  post '/spaces/new' do
    repo = SpaceRepository.new
    new_space = Space.new
    new_space.name = params[:name]
    new_space.description = params[:description]
    new_space.price = params[:price]
    new_space.account_id = session[:user_id]
    repo.create(new_space)
    return erb(:listed_space)
  end

  post '/' do

    @password = params[:password_confirmation]
    @password_confirmation = params[:password]
    @name = params[:name]
    email = params[:email]

    if password_confirmation?
      @error_message = 'Passwords do not match. Please re-submit.'
      return erb(:index)
    end

    repo = AccountRepository.new

    repo.all.each do |account|
      if account.email == email
        @error_message = 'Email already registered. Please re-submit or sign-in.'
        return erb(:index)
      end
    end

    new_account = Account.new

    new_account.email = email
    new_account.password = @password
    new_account.name = @name
    new_account.dob = params[:dob]

    repo.create(new_account)
    return erb(:signup_confirmation)

  end

  get '/sessions/new' do
    return erb(:login)
  end

  post '/sessions/new' do
    email = params[:email]
    @password = params[:password]
    if AccountRepository.new.find_by_email(email) == false
      @error_message = 'Email not recognized'
      return erb(:login)
    else
      @user = AccountRepository.new.find_by_email(email)
      if incorrect_password?
        @error_message = 'Incorrect password please retry'
        return erb(:login)
      else
        session[:user_id] = @user.id
        redirect '/spaces'
      end
    end
  end

  get '/logout' do
    return erb(:logout)
  end

  post '/logout' do
    session[:user_id] = nil
    redirect '/'
  end

  get '/spaces/:id' do
    if session[:user_id] == nil
      return redirect('/sessions/new')
    else
      repo = SpaceRepository.new
      session[:space_id] = params[:id]
      @space = repo.find(session[:space_id])
      return erb(:new_request)
    end
 end

  post '/spaces/request' do
    repo = BookingRepository.new
    new_booking = Booking.new

    new_booking.date = params[:date]
    new_booking.space_id = session[:space_id]
    new_booking.status = "Pending"
    new_booking.account_id = session[:user_id]

    repo.create(new_booking)

    return erb(:request_confirmation)
    
    redirect '/spaces'
  end

  get '/requests/:id' do
    session[:user_id] = params[:id]
    @user_id = params[:id]
    account_repo = AccountRepository.new
    @account = account_repo.find(session[:user_id])
    @space_repo = SpaceRepository.new
    spaces = @space_repo.all
    my_spaces = spaces.select do |space|
      space.account_id == @account.id
    end
    space_ids = my_spaces.map do |space|
      space.id
    end

    booking_repo = BookingRepository.new
    bookings = booking_repo.all

    @my_requested_spaces = bookings.select do |booking|
      space_ids.include?(booking.space_id)
    end
    return erb(:requests)
  end 

  get '/myrequests/:id' do
    session[:user_id] = params[:id]
    @user_id = params[:id]
    
    account_repo = AccountRepository.new
    @account = account_repo.find(session[:user_id])

    @space_repo = SpaceRepository.new
    spaces = @space_repo.all

    booking_repo = BookingRepository.new
    bookings = booking_repo.all

    @my_requested_spaces = bookings.select do |booking|
      booking.account_id == @user_id.to_i
    end

    return erb(:myrequests)
  end 

  get '/requests/confirm/:id' do
      booking_repo = BookingRepository.new
      account_repo = AccountRepository.new
      space_repo = SpaceRepository.new

      session[:booking_id] = params[:id]
      @booking = booking_repo.find(session[:booking_id])

      @booking.account_id
      @account = account_repo.find(@booking.account_id)

      @booking.space_id
      @space = space_repo.find(@booking.space_id)

      return erb(:confirm_request)
  end

  post '/requests/confirm' do
    repo = BookingRepository.new
    booking = repo.find(session[:booking_id])
    status = params[:status]

    if status == "Confirm Request"
      booking.status = 'Confirmed'
      @request_message = 'The booking has been confirmed'
    elsif status == "Deny Request"
      booking.status = 'Denied'
      @request_message = 'The booking has been denied'
    end

    repo.update(booking)

    return erb(:booking_confirmation)

  end

  private

  def password_confirmation?
    return @password_confirmation != @password
  end

  def incorrect_password?
    return BCrypt::Password.new(@user.password) != @password
  end

end



