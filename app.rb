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
end           
