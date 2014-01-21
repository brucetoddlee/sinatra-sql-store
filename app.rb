require 'pry'
require 'sinatra'
require 'sinatra/reloader'
require 'pg'

def dbname
  "storeadminsite"
end

def with_db
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  yield c
  c.close
end

get '/' do
  erb :index
end

# The Products machinery:

# Get the index of products
get '/products' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Get all rows from the products table.
  @products = c.exec_params("SELECT * FROM products;")
  c.close
  erb :products
end

# Get the form for creating a new product
get '/products/new' do
  erb :new_product
end

# POST to create a new product
post '/products' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Insert the new row into the products table.
  c.exec_params("INSERT INTO products (name, price, description) VALUES ($1,$2,$3)",
                  [params["name"], params["price"], params["description"]])

  # Assuming you created your products table with "id SERIAL PRIMARY KEY",
  # This will get the id of the product you just created.
  new_product_id = c.exec_params("SELECT currval('products_id_seq');").first["currval"]
  c.close
  redirect "/products/#{new_product_id}"
end

# Update a product
post '/products/:id' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Update the product.
  c.exec_params("UPDATE products SET (name, price, description) = ($2, $3, $4) WHERE products.id = $1 ",
                [params["id"], params["name"], params["price"], params["description"]])
  c.close
  redirect "/products/#{params["id"]}"
end

get '/products/:id/edit' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @product = c.exec_params("SELECT * FROM products WHERE products.id = $1", [params["id"]]).first
  c.close
  erb :edit_product
end
# DELETE to delete a product
post '/products/:id/destroy' do

  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec_params("DELETE FROM products WHERE products.id = $1", [params["id"]])
  c.close
  redirect '/products'
end

# GET the show page for a particular product
get '/products/:id' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @product = c.exec_params("SELECT * FROM products WHERE products.id = $1;", [params[:id]]).first
  
  @categories_display = ""
  categories_of_product = c.exec_params("SELECT c.name FROM categories AS c INNER JOIN products_categories AS pc ON c.id=pc.category_id INNER JOIN products AS p ON p.id=pc.product_id WHERE p.id = $1", [params["id"]])
  categories_of_product.each do |category|
    @categories_display << %Q(<li>#{category["name"]}</li>)
  end

  c.close
  erb :product
end

def create_products_table
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec %q{
  CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name varchar(255),
    price decimal,
    description text
  );
  }
  c.close
end

def drop_products_table
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec "DROP TABLE products;"
  c.close
end

def seed_products_table
  products = [["Laser", "325", "Good for lasering."],
              ["Shoe", "23.4", "Just the left one."],
              ["Wicker Monkey", "78.99", "It has a little wicker monkey baby."],
              ["Whiteboard", "125", "Can be written on."],
              ["Chalkboard", "100", "Can be written on.  Smells like education."],
              ["Podium", "70", "All the pieces swivel separately."],
              ["Bike", "150", "Good for biking from place to place."],
              ["Kettle", "39.99", "Good for boiling."],
              ["Toaster", "20.00", "Toasts your enemies!"],
             ]

  c = PGconn.new(:host => "localhost", :dbname => dbname)
  products.each do |p|
    c.exec_params("INSERT INTO products (name, price, description) VALUES ($1, $2, $3);", p)
  end
  c.close
end












# The Categories machinery:

# Get the index of categories
get '/categories' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Get all rows from the categories table.
  @categories = c.exec_params("SELECT * FROM categories;")
  c.close
  erb :categories
end

# Get the form for creating a new category
get '/categories/new' do
  erb :new_category
end

# POST to create a new category
post '/categories' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Insert the new row into the categories table.
  c.exec_params("INSERT INTO categories (name, description) VALUES ($1,$2)",
                  [params["name"], params["description"]])

  # Assuming you created your categories table with "id SERIAL PRIMARY KEY",
  # This will get the id of the category you just created.
  new_category_id = c.exec_params("SELECT currval('categories_id_seq');").first["currval"]
  c.close
  redirect "/categories/#{new_category_id}"
end

# Update a category
post '/categories/:id' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Update the category.
  c.exec_params("UPDATE categories SET (name, description) = ($2, $3) WHERE categories.id = $1 ",
                [params["id"], params["name"], params["description"]])
  c.close
  redirect "/categories/#{params["id"]}"
end

get '/categories/:id/edit' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @category = c.exec_params("SELECT * FROM categories WHERE categories.id = $1", [params["id"]]).first
  c.close
  erb :edit_category
end
# DELETE to delete a category
post '/categories/:id/destroy' do

  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec_params("DELETE FROM categories WHERE categories.id = $1", [params["id"]])
  c.close
  redirect '/categories'
end

# GET the show page for a particular category
get '/categories/:id' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @category = c.exec_params("SELECT * FROM categories WHERE categories.id = $1;", [params[:id]]).first
  
  @products_display = ""
  products_of_category = c.exec_params("SELECT p.name FROM products AS p INNER JOIN products_categories AS pc ON p.id=pc.product_id INNER JOIN categories AS c ON c.id=pc.category_id WHERE c.id = $1", [params["id"]])
  products_of_category.each do |product|
    @products_display << %Q(<li>#{product["name"]}</li>)
  end

  c.close
  erb :category
end

def create_categories_table
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec %q{
  CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name varchar(255),
    description text
  );
  }
  c.close
end

def drop_categories_table
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec "DROP TABLE categories;"
  c.close
end

def seed_categories_table
  categories = [["Household", "Stuff for your house."],
             ["Dangerous Items", "Don't hurt yourself."],
             ["Clothing", "Stuff you wear."],
             ["Education", "Stuff for learnin'."],
             ["Sporting Goods", "Stuff for exercising."],
             ["Kitchen", "Stuff for your kitchen."],
           ]

  c = PGconn.new(:host => "localhost", :dbname => dbname)
  categories.each do |p|
    c.exec_params("INSERT INTO categories (name, description) VALUES ($1, $2);", p)
  end
  c.close
end


# The Products-Categories association machinery:

def create_products_categories_table
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec %q{
  CREATE TABLE products_categories (
    id SERIAL PRIMARY KEY,
    product_id integer,
    category_id integer
  );
  }
  c.close
end

def drop_products_categories_table
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec "DROP TABLE products_categories;"
  c.close
end

def seed_products_categories_table
  products_categories = [
            [1,2],
            [2,1],
            [2,3],
            [3,1],
            [4,4],
            [5,4],
            [6,4],
            [7,5],
            [8,1],
            [8,2],
            [8,6],
            [9,1],
            [9,6],
           ]

  c = PGconn.new(:host => "localhost", :dbname => dbname)
  products_categories.each do |p|
    c.exec_params("INSERT INTO products_categories (product_id, category_id) VALUES ($1, $2);", p)
  end
  c.close
end




def add_category_to_product(product, category)


end

def remove_category_from_product(product, category)


end









