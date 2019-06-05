import ballerina/config;
import ballerina/http;
import ballerina/log;
import ballerina/io;
import ballerina/time;
http:Client httpEndpoint = new("https://localhost:9443/", config = {
    auth: {
        scheme: http:BASIC_AUTH,
        config: {
            username: "admin",
            password: "admin"
        }
    }
});

public function main() {
    var isValid = validateAccessToken("c92dbab2-434f-3554-85b1-fb8fd46e0978");
}

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

public function isValidUser(string tokenUsername, string givenUsername) returns boolean {
    return tokenUsername == givenUsername;
}