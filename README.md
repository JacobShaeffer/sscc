# README

# Project Setup

## Install Ruby 3.2.1

### Either directly
https://www.ruby-lang.org/en/documentation/installation/#rubyinstaller

### Or via Ruby Version Manager if you think you may ever want to have multiple versions of Ruby for different projects
https://rvm.io/rvm/install

## make sure sqlite3 is installed
``` sqlite3 --version ```

## install gems
``` bundle install ```

## migrate database
``` rails db:migrate ```

## test project
``` rails s ```
Then navigate to localhost:3000 in any browser

## Congrats


# Add an admin user
## Create the user via console
```
rails c 
User.create!({:email => "test@test.com", :role => "admin", :password => "password", :password_confirmation => "password", :name => "test" })
```
