import ballerina/config;
import ballerina/http;
import ballerina/log;
import ballerina/io;
import ballerina/time;
final string filter_name_header = "X-filterName";

final string filter_name_header_value = "RequestFilter-1";

public type RequestFilter object {

    public function filterRequest(http:Caller caller, http:Request request,
                        http:FilterContext context)
                        returns boolean {
        request.setHeader(filter_name_header, filter_name_header_value);
        log:printInfo("Request Interceptor......");
        var isValid = validateAccessToken("c92dbab2-434f-3554-85b1-fb8fd46e0978");
        return true;
    }

    public function filterResponse(http:Response response,
                                   http:FilterContext context)
                                    returns boolean {
        log:printInfo("Interceptor Response......");
        return true;
    }
};

RequestFilter filter = new;

listener http:Listener echoListener = new http:Listener(9091,
                                            config = { filters: [filter]});

@http:ServiceConfig {
    basePath: "/hello"
}
service echo on echoListener {
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/sayHello"
    }
    resource function echo(http:Caller caller, http:Request req) {
        http:Response res = new;
        log:printInfo("Service reached......");
        res.setHeader(filter_name_header, req.getHeader(filter_name_header));
        res.setPayload("Hello, World!");
        var result = caller->respond(res);
        if (result is error) {
           log:printError("Error sending response", err = result);
        }
    }
}


http:Client httpEndpoint = new("https://localhost:9443/", config = {
    auth: {
        scheme: http:BASIC_AUTH,
        config: {
            username: "admin",
            password: "admin"
        }
    }
});

# Description
#
# + token - access token to be validated
# + return - returns whether the access token is valid or not
public function validateAccessToken(string token) returns (boolean) {
    http:Request req = new;
    req.setPayload("token=" + token);
    // req.addHeader("Content-Type", "application/x-www-form-urlencoded");
    error ? x = req.setContentType("application/x-www-form-urlencoded");
    var response = httpEndpoint->post("/oauth2/introspect", req);
    var isValid = false;
    if (response is http:Response) {
        var result = response.getJsonPayload();
        if result is error {
            log:printError("Payload Error ", err = result);
        } else {
            io:println(result);
        }
        // json|error j = json.convert(result);
        if (result is json) {
            io:println(result.active);
            boolean|error resActive = boolean.convert(result.active);
            if (resActive is boolean) {
                isValid = resActive;
            }
            if (isValid) {
                int|error resExp = int.convert(result.exp);
                if (resExp is int) {
                    var exp = isExpired(resExp);
                    // todo Check user
                    return exp;
                }
            }
        }
        return isValid;
    } else {
        log:printError("Failed to call the introspection endpoint.", err = response);
        return isValid;
    }
}

function isExpired(int timeVal) returns boolean {
    time:Time time = time:currentTime();
    int timeNow = time.time;
    if (timeNow/1000 < timeVal) {
        return true;
    }else{
        io:println("Token is expired");
        return false;
    }
}

function isValidUser(string tokenUsername, string givenUsername) returns boolean {
    return tokenUsername == givenUsername;
}
