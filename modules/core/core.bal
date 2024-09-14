import ballerina/http;
import ballerinax/mysql;

// Port
configurable int SERVER_PORT = 8080;

// DB Credentials
configurable string DB_USER = ?;
configurable string DB_PASSWORD = ?;
configurable string DB_HOST = ?;
configurable int DB_PORT = ?;
configurable string DB_NAME = ?;

public final mysql:Client dbClient = check new (
    host = DB_HOST,
    user = DB_USER,
    password = DB_PASSWORD,
    port = DB_PORT,
    database = DB_NAME
);

public listener http:Listener httpListner = new http:Listener(SERVER_PORT);

public enum ACTION {
    READ = "read",
    CREATE = "create",
    UPDATE = "update",
    DELETE = "delete"
}

public enum RESOURCE {
    PROJECT = "project"
}