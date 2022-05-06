require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

helpers do
  def list_completed?(list)
    todos_count(list) > 0 && todos_remaining_count(list) == 0
  end

  def list_class(list)
    "complete" if list_completed?(list)
  end

  def todos_count(list)
    list[:todos].size
  end

  def todos_remaining_count(list)
    list[:todos].select { |todo| !todo[:completed] }.size
  end

  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_completed?(list) }

    incomplete_lists.each { |list| block.call(list, lists.index(list)) }
    complete_lists.each { |list| block.call(list, lists.index(list)) }
  end

  def sort_todos(todos, &block)
    incomplete_todos = {}
    complete_todos = {}

    todos.each_with_index do |todo, index|
      if todo[:completed]
        complete_todos[todo] = index
      else
        incomplete_todos[todo] = index
      end
    end

    incomplete_todos.each(&block)
    complete_todos.each(&block)
  end
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

get "/lists" do
  @lists = session[:lists]

  erb :lists, layout: :layout
end

get "/lists/new" do
  erb :new_list, layout: :layout
end

# Return an error message if the name is invalid. Return nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  elsif session[:lists].any? { |list| list[:name] == name }
    "List name must be unique."
  end
end

# Return an error message if the todo is invalid. Return nil if todo is valid.
def error_for_todo(todo)
  unless (1..100).cover? todo.size
    "Todo must be between 1 and 50 characters."
  end
end

# Create a new todo list
post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

get "/lists/:id" do
  @list_id = params[:id].to_i

  if (0..session[:lists].size).cover? @list_id
    @list = session[:lists][@list_id]
    erb :list
  else
    session[:error] = "List with the id #{@list_id} was not found."
    redirect "/lists"
  end
end

# Edit an existing todo list
get "/lists/:id/edit" do
  id = params[:id].to_i

  if (0..session[:lists].size).cover? id
    @list = session[:lists][id]
    erb :edit_list
  else
    session[:error] = "List with the id #{id} was not found."
    redirect "/lists"
  end
end

# Update an existing todo list
post "/lists/:id" do
  list_name = params[:list_name].strip
  id = params[:id].to_i
  error = error_for_list_name(list_name)
  @list = session[:lists][id]

  if error
    session[:error] = error
    erb :edit_list
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists/#{id}"
  end
end

# Delete a todo list
post "/lists/:id/delete" do
  id = params[:id].to_i

  if (0..session[:lists].size).cover? id
    session[:lists].delete_at(id)
    session[:success] = "The list has been deleted."
    redirect "/lists"
  else
    session[:error] = "List with the id #{id} was not found."
    redirect "/lists"
  end
end

# Add a new todo list to a list
post "/lists/:id/todos" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  todo = params[:todo].strip
  error = error_for_todo(todo)

  if error
    session[:error] = error
    erb :list
  else
    @list[:todos] << { name: todo, completed: false }
    session[:success] = "The todo has been added."
    redirect "/lists/#{@list_id}"
  end
end

# Delete a todo from a list
post "/lists/:list_id/todos/:todo_id/delete" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  todo_id = params[:todo_id].to_i
  @list[:todos].delete_at(todo_id)
  session[:success] = "The todo has been deleted."
  redirect "/lists/#{@list_id}"
end

# Mark a todo as complete
post '/lists/:list_id/todos/:todo_id/complete' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  todo_id = params[:todo_id].to_i
  @todo = @list[:todos][todo_id]
  completed = params[:completed] == "true"
  @todo[:completed] = completed
  session[:success] = "The todo has been updated."
  redirect "/lists/#{@list_id}"
end

# Mark all todos in a list as complete
post '/lists/:id/todos/complete' do
  @id = params[:id].to_i
  @list = session[:lists][@id]

  @list[:todos].each do |todo|
    todo[:completed] = true unless todo[:completed]
  end

  session[:success] = "All todos have been completed."
  redirect "/lists/#{@id}"
end
