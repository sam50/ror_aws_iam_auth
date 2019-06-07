require "base64"
require "net/http"
require "uri"
require "rack"
require "json"
require "nokogiri"
require "jwt"

class AuthenticateUser
  prepend SimpleCommand

  def initialize(iam_http_request_method, iam_request_url,iam_request_body, iam_request_headers)
    @iam_http_request_method=Base64.decode64(iam_http_request_method)
    @iam_request_url=Base64.decode64(iam_request_url)
    @iam_request_body=Base64.decode64(iam_request_body)
    @iam_request_headers=Base64.decode64(iam_request_headers)
  end

  def call
    JsonWebToken.encode(user_id: user.id) if user
  end

  private

  attr_accessor :name, :iamarn

  def user
    #puts "DEBUG #{@iam_http_request_method}, #{@iam_request_url}, #{@iam_request_body}, #{@iam_request_headers}"
    iamarn = authenticate_iam
    if iamarn
      user = User.find_by_iamarn(iamarn)
      return user if user
    end

    errors.add :user_authentication, 'invalid credentials'
    nil
  end
  def authenticate_iam
    # uri = URI.parse(@iam_request_url)
    # Really? that would be a dump idea, never execute requests to the URLs specified by the client :)
    # as of right now, there is no great way to check that we are sending request to STS except for knowing this in advance
    # how Vault people do this - add a configuration option
    uri = URI.parse("https://sts.amazonaws.com/")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = "Net::HTTP::#{@iam_http_request_method.capitalize}".constantize.new(uri.request_uri)
    request.set_form_data(Rack::Utils.parse_nested_query(@iam_request_body))
    headers = JSON.parse(@iam_request_headers)
    headers.each do |header, value|
	    request[header]=value
    end
    # This is hardcoded here for the demo, you should keep it as a variable
    # it's about server ID that client adds to a signed request
    # Needed for security reason because you can verify the signed request from any place in the world
    # you (a server) need to know that this request was signed by a client for this particular server 
    # so that one will not send a request signed for DEV server to a PROD server, for example.
    if headers['X-APP-ID'] != 'APP1-live'
	    return false
    end
    response = http.request(request)
    puts response.code
    puts response.body
    puts response.content_type
    if response.code != '200' || response.body.empty?
       return false
    else
       xml = Nokogiri::XML(response.body)
       stsarn = xml.remove_namespaces!.xpath("GetCallerIdentityResponse/GetCallerIdentityResult/Arn").text
       if stsarn.empty?
	  return false
       else	  
          return stsarn.gsub("arn:aws:sts","arn:aws:iam").gsub("assumed-role","role").gsub(/\/[A-z0-9\-]*$/,"")
       end
    end
  return false
  end
end
