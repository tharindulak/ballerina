import ballerina/io;
import ballerina/log;
import cellery/model;
import ballerina/system;
import ballerina/filepath;

public function loadConfig() returns (model:Auth) {
    model:Auth config = {
            idpHost:"",
            idpPort:0,
            username:"",
            password:""
    };
    log:printDebug("Started to read config file");
    config.idpHost = system:getEnv("IDP_HOST");
    int|error idpPort = int.convert(system:getEnv("IDP_PORT"));
    if (idpPort is int) {
        config.idpPort = idpPort;
    }
    config.username = system:getEnv("IDP_USERNAME");
    config.password = system:getEnv("IDP_PASSWORD");
    log:printDebug("Intercptor configurations \n" + "IDP host:" + config.idpHost + " IDP port:" + config.idpPort + " IDP username:" + config.username + " IDP password:" + config.password);
    return config;
}
// }
