class App < Sinatra::Base

	enable :sessions
	db = SQLite3::Database.new("db/contact.db")
	get '/' do
		slim(:index)
	end
	get '/login' do
		username = params[:username]
		password = params[:password]
		if username == "" || password == ""
			session[:error] = "Please enter a username and a password."
			redirect('/')
		else
			db_password = db.execute("SELECT password FROM users WHERE name=?", username)
			if db_password == []
				session[:error] = "Username doesn't exist"
				redirect('/')
			else
				db_password = db_password[0][0]
				password_digest =  db_password
				password_digest = BCrypt::Password.new( password_digest )
				if password_digest == password
					user_id = db.execute("SELECT id FROM users WHERE name=?", username)
					user_id = user_id[0][0]
					session[:id] = user_id
					redirect('/contacts')
				else
					session[:id] = nil
					session[:error] = "Wrong password or username"
					redirect('/')
				end
			end
		end
	end
	post '/register' do
		db = SQLite3::Database.new("db/contact.db")
		username = params[:username]
		password = BCrypt::Password.create( params[:password] )
		password2 = BCrypt::Password.create( params[:password2] )
		if username == "" || password == "" || password == ""
			session[:error] = "Please enter a username and password."
		elsif params[:password] != params[:password2]
			session[:error] = "Passwords don't match"
		elsif db.execute("SELECT name FROM users WHERE name=?", username) != []
			session[:error] = "Username already exists"
		elsif username.size > 16
			session[:error] = "Användarnamnet får max vara 16 karaktärer långt"
		else
			db.execute("INSERT INTO users ('name', 'password') VALUES (?,?)", [username, password])
		end
		redirect('/')
	end
	get '/contacts' do
		if session[:id]
			username = db.execute("SELECT name FROM users WHERE id=?", session[:id])
			added_friends = db.execute("SELECT name, id FROM users WHERE id IN (SELECT b FROM friends WHERE a=? AND relation=1)", session[:id])
			accepted_friends = db.execute("SELECT name, id FROM users WHERE id IN (SELECT a FROM friends WHERE b=? AND relation=1)", session[:id])
			friend_list = []
			accepted_friends.each do |friend|
				friend_list << friend
			end
			added_friends.each do |friend|
				friend_list << friend
			end
			contacts = []
			requests = db.execute("SELECT id, name FROM users WHERE id IN (SELECT a FROM friends WHERE b=? AND relation=0)", session[:id])
			your_inf = db.execute("SELECT info, type FROM contact_info WHERE user_id=?", session[:id])
			slim(:contacts, locals:{contacts:friend_list, name:username, info:your_inf, requests:requests})
		else
			session[:error] = "Du är inte inloggad för tillfället"
			redirect('/')
		end
	end
	get '/logout' do
		session[:id] = nil
		redirect("/")
	end
end           
