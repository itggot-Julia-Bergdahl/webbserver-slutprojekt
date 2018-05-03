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
	post '/add_friend' do
		if session[:id] 
			if db.execute("SELECT * FROM friends WHERE a=? AND b=?", [session[:id], params[:add]]) == [] and db.execute("SELECT * FROM friends WHERE a=? AND b=?", [params[:add], session[:id]]) == []
			db.execute("INSERT INTO friends(a, b, relation) VALUES(?,?,?)", [session[:id], params[:add], 0])
			redirect('/contacts')
			else
			session[:error] = "You already have this person as a friend"
			redirect("/contacts")
			end
		else
			redirect('/')
		end
	end
	post '/accept_friend' do
		if session[:id]
			db.execute("UPDATE friends set relation=1 WHERE a=? AND b=?", [params[:acc_id], session[:id]])
			redirect("/contacts")
		else
			redirect("/")
		end
	end
	get '/friends' do
		if session[:id]
			added_friends = db.execute("SELECT name, id FROM users WHERE id IN (SELECT b FROM friends WHERE a=? AND relation=1)", session[:id])
			accepted_friends = db.execute("SELECT name, id FROM users WHERE id IN (SELECT a FROM friends WHERE b=? AND relation=1)", session[:id])
			friend_list = []
			accepted_friends.each do |friend|
				friend_list << friend
			end
			added_friends.each do |friend|
				friend_list << friend
			end
			contact_info = []
			friend_list.each do |friend|
				contact_info << db.execute("SELECT * FROM contact_info WHERE user_id=?", friend[1])
			end
			p contact_info
			slim(:friends, locals:{contact_info:contact_info, friends:friend_list})
		else
			redirect("/")
		end
	end
	post '/contact_info' do
		if session[:id]
			db.execute("INSERT INTO contact_info(user_id, info, type) VALUES(?,?,?)", [session[:id], params[:info], params[:contact]])
			redirect("/contacts")
		else
			redirect("/")
		end
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
	get '/search_user' do
		results = db.execute("SELECT name, id FROM users WHERE name LIKE ?", ["%"+params[:search]+"%"])
		slim(:search, locals:{results:results})
	end
end           
