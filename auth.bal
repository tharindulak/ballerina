import ballerina/config;
import ballerina/http;
import ballerina/log;
import ballerina/io;
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
    // config:setConfig("b7a.users.tom.password", "1234");
    http:Request req = new;
    req.setPayload("token=ee2d9ae7-40b6-3515-b015-6ee566dc53a9");
    // req.addHeader("Content-Type", "application/x-www-form-urlencoded");
    error? x = req.setContentType("application/x-www-form-urlencoded");
    var response = httpEndpoint->post("/oauth2/introspect", req);

    if (response is http:Response) {
        var result = response.getTextPayload();
        if result is error {
            log:printError("Payload Error ", err = result);
        } else {
            io:println(result);
        }
    } else {
        log:printError("Failed to call the endpoint.", err = response);
    }
}
