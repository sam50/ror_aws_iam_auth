# README

This is a very basic Ruby on Rails Application that uses AWS IAM roles to authenticate clients.
The method used here - via signed request for AWS STS for sts:GetCallerIdentity request. The authenticated user than gets a JWT token
The application was created  with `rails new api1 --api` it has a model Users and a scaffold Items 

Here is what happens here(not exactly, but mainly correct)

![Schema](schema.png?raw=true "Schema")


* Things needed in AWS:

2 instances, one for client one for server.
IAM role for client instance, assigned as Instance profile during instance creation. Name doesn't matter, also take the IAM role ARN from IAM it looks like `arn:aws:iam::<accountID>:role/<role-name>` be sure to add this ARN when creating user on the server
Client needs python2.7 and `botocore` package (`pip install botocore`)
Server needs ruby 
There has to be a connectivity between the client and server, since this is a demo only  the port 3000 will be optimal.

* Ruby version

2.6.3

* System dependencies

`bundle install`
should do it all. Aside of basic rails and what comes with that, this application uses 'JWT' and 'simple_command'

* Running

```bash
git clone https://github.com/sam50/ror_aws_iam_auth
cd ror_aws_iam_auth
bundle install
rake db:migrate
rails c
User.create!(name:"client1", iamarn: "<Your role ARN here arn:aws:iam::xxxx:role/role-name")
rails s -b 0.0.0.0 3000

```

* Client

Written in python, see client/api_client.py a little bit adapted version of sign_requests.py for Vault

```bash
./api_client.py <AppId> http://<server>/authenticate
Blah-blah-Debug
{"auth_token":"eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJleHAiOjE1NTk5OTYyMjZ9.H9zjYGAIUwBZY5Kb3KlF9eegTph9GmBBbLNrki1450U"}

```
You can use that JWT token for working with the application  now


```bash
curl -H "Authorization: eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJleHAiOjE1NTk5OTYyMjZ9.H9zjYGAIUwBZY5Kb3KlF9eegTph9GmBBbLNrki1450U"  http://<server>/items
```


Please note,  the AppId here is just a string, ideally it identifies the particular instance of the application which client is trying to authenticate to. This is a demo appliaction so the value is hardcoded in app/commands/authenticate_user.rb:57 read the comments

* Main thing to watch

app/commands/authenticate_user.rb
