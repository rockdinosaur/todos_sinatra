require "sinatra"
require "sinatra/content_for"
require "sinatra/reloader"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# View all lists
get "/lists" do
  @lists = session[:lists]
  erb :lists
end

# Render the new list form
get "/lists/new" do
  erb :new_list
end

# Validate list name input
def list_name_valid?(name)
  if name.empty? || name.length > 100
    session[:error] = "List name must be between 1 and 100 chars."
    false
  elsif session[:lists].any? { |list| list[:name] == name }
    session[:error] = "List name already in use."
    false
  else
    true
  end
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip
  if list_name_valid?(list_name)
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "The list has been created!"
    redirect "/lists"
  else
    erb :new_list
  end
end

get "/lists/:id" do
  @id = params[:id].to_i
  @list = session[:lists][@id]
  erb :list
end

# Edit an existing Todo
get "/lists/:id/edit" do
  @id = params[:id].to_i
  @list = session[:lists][@id]
  erb :edit
end

# Update an existing todo
post "/lists/:id" do
  if list_name_valid?(params[:list_name].strip)
    session[:lists][@id][:name] = params[:list_name]
    session[:success] = "List has been updated!"
    redirect "/lists/#{@id}"
  else
    erb :edit_list
  end
end
