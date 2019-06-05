import ballerina/config;
import ballerina/http;
import ballerina/log;
import ballerina/io;
import ballerina/time;
import cellery/reader;
import cellery/model;
import cellery/validator;
import ballerina/mysql;
import ballerina/sql;

final string filter_name_header = "username";

model:Auth config = {
        idpHost:"",
        idpPort:0,
        username:"",
        password:""
};

public type RequestFilter object {
    public function filterRequest(http:Caller caller, http:Request request,
                        http:FilterContext context)
                        returns boolean {
        log:printDebug("Request was intercepted ......");
        string header = "";
        if(request.hasHeader(filter_name_header)){
            header = request.getHeader(filter_name_header);
        }
        if "" != header {
            request.setHeader(filter_name_header, "");
            return true;
        }
        var params = request.getQueryParams();
        var token = <string>params.token;
        var username = <string>params.username;
        if (config.idpPort == 0 && config.idpHost=="" && config.username == "" && config.password == "" ) {
            config = untaint reader:loadConfig();
        }
        boolean|error isValid = validator:validateAccessToken(username, token, config);
        io:println(isValid);
        if (isValid is boolean) {
            io:println(isValid);
            if isValid {
                string|error validStr = string.convert(isValid);
                request.setHeader(filter_name_header, username);
                log:printInfo("The token is valid");
                return true;
            } else {
                request.setHeader(filter_name_header, "");
                log:printError("The token is not valid");
            // checkpanic caller->respond("User is unauthorized");
                return true;
            }
        }else {
            log:printError("Error calling validator.bal");
            return false;
        }
    }

    public function filterResponse(http:Response response,
                                   http:FilterContext context)
                                    returns boolean {
        return true;
    }
};

RequestFilter filter = new;

listener http:Listener echoListener = new http:Listener(9091, config = { filters: [filter]});

@http:ServiceConfig {
    basePath: "/image"
}
service echo on echoListener {
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/images/{orgname}/{imageName}"
    }
    resource function echo(http:Caller caller, http:Request req, string orgname, string imageName) {
        log:printInfo("Service hit " + orgname + " " + imageName);
        getImage (orgname, imageName);
        var result = caller->respond("Hello, World!");
        if (result is error) {
            log:printError("Error sending response", err = result);
        }
    }
    
}
mysql:Client testDB = new({
        host: "localhost",
        port: 3306,
        name: "CELLERY_HUB",
        username: "root",
        password: "mysqlRoot",
        dbOptions: { useSSL: false }
    });

function getImage(string orgName, string imageName) {
    var ret = testDB->select("SELECT SUM(PULL_COUNT) as PULL_COUNT, REGISTRY_ARTIFACT_IMAGE.ORG_NAME, 
                              REGISTRY_ARTIFACT_IMAGE.DESCRIPTION, REGISTRY_ARTIFACT_IMAGE.VISIBILITY, MAX(UPDATED_DATE) as UPDATED_DATE
                              FROM CELLERY_HUB.REGISTRY_ARTIFACT_IMAGE
                              INNER JOIN REGISTRY_ARTIFACT ON REGISTRY_ARTIFACT_IMAGE.ARTIFACT_IMAGE_ID=REGISTRY_ARTIFACT.ARTIFACT_IMAGE_ID
                              WHERE ORG_NAME=? AND IMAGE_NAME=?
                              GROUP BY REGISTRY_ARTIFACT_IMAGE.IMAGE_NAME;", (), orgName, imageName);
    json jsonReturnValue = {};
    if (ret is table<record {}>) {
        // Convert the sql data table into JSON using type conversion
        var jsonConvertRet = json.convert(ret);
        if (jsonConvertRet is json) {
            jsonReturnValue = jsonConvertRet;
        } else {
            jsonReturnValue = { "Status": "Data Not Found", "Error": "Error occurred in data conversion" };
            log:printError("Error occurred in data conversion", err = jsonConvertRet);
        }
    } else {
        jsonReturnValue = { "Status": "Data Not Found", "Error": "Error occurred in data retrieval" };
        log:printError("Error occurred in data retrieval", err = ret);
    }
    if jsonReturnValue[0].VISIBILITY == "private" {
        io:println("IMAGE is private");
    }
    io:println(jsonReturnValue[0]);
    getKeywords(orgName, imageName);
}

function getKeywords(string orgName,string imageName) {
    var ret = testDB->select("SELECT IMAGE_KEYWORDS.KEYWORD
                              FROM CELLERY_HUB.REGISTRY_ARTIFACT_IMAGE
                              INNER JOIN IMAGE_KEYWORDS ON REGISTRY_ARTIFACT_IMAGE.ARTIFACT_IMAGE_ID=IMAGE_KEYWORDS.ARTIFACT_IMAGE_ID
                              WHERE ORG_NAME=? AND IMAGE_NAME=?", (), orgName, imageName);
    json jsonReturnValue = {};
    if (ret is table<record {}>) {
        // Convert the sql data table into JSON using type conversion
        var jsonConvertRet = json.convert(ret);
        if (jsonConvertRet is json) {
            jsonReturnValue = jsonConvertRet;
        } else {
            jsonReturnValue = { "Status": "Data Not Found", "Error": "Error occurred in data conversion" };
            log:printError("Error occurred in data conversion", err = jsonConvertRet);
        }
    }
    // foreach var val in jsonReturnValue {
    //     io:println("fruit: " + v);
    // }
    io:println(jsonReturnValue);
}
