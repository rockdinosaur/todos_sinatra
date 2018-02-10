require "sinatra"
require "sinatra/content_for"
require "sinatra/reloader" if development?
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
  @lists = session[:lists]
  @lists_progress = []
  @lists.each do |list|
    completed_todos = 0

    if list[:todos].empty?
      @lists_progress << "empty"
      next
    end

    total_todos = list[:todos].length

    list[:todos].each do |todo|
      completed_todos += 1 if todo[:completed]
    end

    if completed_todos == total_todos
      @lists_progress << "done"
    else
      @lists_progress << "#{completed_todos} / #{total_todos}"
    end

  end
end

helpers do
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

  # Validate todo name
  def todo_name_valid?(list, todo_name)
    if todo_name.empty? || todo_name.length > 100
      session[:error] = "Todo name must be between 1 and 100 chars."
      false
    elsif list[:todos].any? { |todo| todo[:name] == todo_name }
      session[:error] = "Todo already on list!"
      false
    else
      true
    end
  end

  # Check if List todos complete
  def list_complete?(list)
    list[:todos].all? { |todo| todo[:completed] } && list[:todos].length > 0
  end

  def todo_complete?(todo)
    todo[:completed]
  end

  def sort_lists(lists, &block)
    completed_lists, incomplete_lists = lists.partition { |list| list_complete?(list) }
    incomplete_lists.each { |list| block.call(list, lists.index(list)) }
    completed_lists.each { |list| block.call(list, lists.index(list)) }
  end

  def sort_todos(todos, &block)
    completed_todos, incomplete_todos = todos.partition { |todo| todo_complete?(todo) }
    incomplete_todos.each{ |todo| block.call(todo, todos.index(todo)) }
    completed_todos.each{ |todo| block.call(todo, todos.index(todo)) }
  end

  def list_class(list)
    list_complete?(list) ? "complete" : ""
  end

  def list_progression(list)
    "#{list[:todos].select { |todo| todo[:completed] }.length} / #{list[:todos].length}"
  end
end

get "/" do
  redirect "/lists"
end

# View all lists
get "/lists" do
  erb :lists
end

# Render the new list form
get "/lists/new" do
  erb :new_list
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

# Delete a list
post "/lists/:list_id/destroy" do
  @lists.delete_at(params[:list_id].to_i)
  session[:success] = "List has been deleted!"
  redirect "/lists"
end

get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = @lists[@list_id]
  erb :list
end

# Edit an existing Todo
get "/lists/:id/edit" do
  @list_id = params[:id].to_i
  @list = @lists[@list_id]
  erb :edit
end

# Update an existing todo
post "/lists/:id" do
  @list_id = params[:id].to_i
  @new_list_name = params[:list_name].strip
  if list_name_valid?(@new_list_name)
    session[:lists][@id][:name] = @new_list_name
    session[:success] = "List has been updated!"
    redirect "/lists/#{@list_id}"
  else
    erb :edit
  end
end

# Destroy a todo from list
post "/lists/:list_id/todos/:todo_idx/destroy" do
  list_id = params[:list_id].to_i
  @lists[list_id][:todos].delete_at(params[:todo_idx].to_i)
  session[:success] = "The todo has been deleted"
  redirect "/lists/#{list_id}"
end

# Add a todo to List
post "/lists/:list_id/todos" do
  list_id = params[:list_id].to_i
  @list = @lists[list_id]
  todo_name = params[:todo].strip
  if todo_name_valid?(@list, todo_name)
    @list[:todos] << { name: params[:todo], completed: false }
    session[:success] = "The todo was added!"
    redirect "/lists/#{list_id}"
  else
    @list_id = list_id
    erb :list
  end
end

# Update Todo
post "/lists/:list_id/todos/:todo_id" do
  @list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  @list = @lists[@list_id]
  if params[:completed] == 'true'
    @list[:todos][todo_id][:completed] = false
  else
    @list[:todos][todo_id][:completed] = true
  end
  session[:success] = "Todo has been updated!"
  redirect "/lists/#{@list_id}"
end

# Complete All Todos of a list
post "/lists/:list_id/completeall" do
  @list_id = params[:list_id].to_i
  @list = @lists[@list_id]
  @list[:todos].each do |todo|
    todo[:completed] = true
  end
  session[:success] = "All todos completed!"
  redirect "/lists/#{@list_id}"
end
