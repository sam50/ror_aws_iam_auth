#!/usr/bin/env python
import botocore.session
from botocore.awsrequest import create_request_object
import json
import base64
import sys
import urllib2
import urllib

# Congrats, 10min of Stackoverflow and you are a Python developer


# Sign a request to the AWS STS with AWS creds(that are bound to IAM role), BUT DO NOT SEND IT TO STS 
# all this is done with AWS SDK
def generate_sts_request(AppId):
    session = botocore.session.get_session()
    client = session.create_client('sts')
    endpoint = client._endpoint
    operation_model = client._service_model.operation_model('GetCallerIdentity')
    request_dict = client._convert_to_request_dict({}, operation_model)

    request_dict['headers']['X-APP-ID'] = AppId

    request = endpoint.create_request(request_dict, operation_model)

    return {
        'iam_http_request_method': base64.b64encode(request.method),
        'iam_request_url':         base64.b64encode(request.url),
        'iam_request_body':        base64.b64encode(request.body),
        'iam_request_headers':     base64.b64encode(json.dumps(dict(request.headers))),
    }


# Now take that signed request and send it to the API server, so that IT can send it to the STS    
def get_token(signed_request, url):
    method = "POST" # unlike in iam_http_request_method that comes from AWS SDK, we know %100 that here we should have POST
    handler = urllib2.HTTPHandler()
    opener = urllib2.build_opener(handler)
    data = json.dumps((signed_request))
    request = urllib2.Request(url, data=data)
    request.add_header("Content-Type",'application/json')
    request.get_method = lambda: method
    #add try-catch
    connection = opener.open(request)
    return connection.read()

if __name__ == "__main__":
    AppId = sys.argv[1]
    url = sys.argv[2]
    print(get_token(generate_sts_request(AppId),url))

# But hey, what do I do with that token? well:
# Try to get anything from server without it
#   $ curl http://<addr>/items
# And that how it works, nothing special, a basic JWT thing
# curl -H "Authorization: <token>"  http://<addr>/items
