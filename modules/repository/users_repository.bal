import time_tracker_2.core;

import ballerina/http;
import ballerina/jwt;
import ballerina/sql;

isolated function checkCredentials(string username, string password) returns int|error {
    sql:ParameterizedQuery query = `SELECT user_id FROM users where username = ${username} and password = ${password}`;
    int userId = check core:dbClient->queryRow(query);
    return userId;
}

isolated function generateJWT(string username, int userId) returns string|error {
    jwt:IssuerConfig issuerConfig = {
        username: username,
        issuer: "wso2",
        audience: "vEwzbcasJVQm1jVYHUHCjhxZ4tYa",
        expTime: 3600,
        customClaims: {
            "userId": userId
        },
        signatureConfig: {
            algorithm: "RS256",
            config: {
                keyFile: "./resources/private.key"
            }
        }
    };
    string jwt = check jwt:issue(issuerConfig);
    return jwt;
}

isolated function getUserRole(int userId) returns UserRole|error {
    sql:ParameterizedQuery query = `
        SELECT id, role_name FROM roles 
        WHERE id = (SELECT role_id FROM users 
                        WHERE user_id = ${userId})
    `;
    UserRole userRole = check core:dbClient->queryRow(query);
    return userRole;
}

isolated function isUserAuthorized(
        UserRole userRole,
        string permissionResource,
        string action,
        ()|int projectId,
        int userId
) returns boolean|error|http:Forbidden & readonly {
    if (userRole.roleId == 1) {
        return true;
    }

    // Get if the user has any action under the specified permissionResource.
    boolean isPermissionAvailable = check isRolePermissionAvailable(roleId = userRole.roleId, permissionResource = permissionResource, action = action);

    match action {
        core:READ => {
            // CHeck if this user has the permission to read
            if (isPermissionAvailable) {
                return true;
            }

            // if count is not equal to 1 that means this user does tno have the permission read. so we check if this project belongs to the user who made the request. nil == null
            if (projectId !is ()) {
                boolean isMember = check isUserInProject(userId = userId, projectId = projectId);
                if (isMember) {
                    return true;
                }
            }
        }

        core:CREATE => {
            if (isPermissionAvailable) {
                return true;
            }
        }

        core:UPDATE => {
            if (isPermissionAvailable) {
                return true;
            }

            if (projectId !is ()) {
                User projectCreator = check getProjectCreator(projectId);
                if (projectCreator.userId == userId) {
                    return true;
                }
            }
        }

        core:DELETE => {
            if (projectId !is ()) {
                User projectCreator = check getProjectCreator(projectId);
                if (projectCreator.userId == userId) {
                    return true;
                }
            }
        }

        _ => {
            return error("Wrong resource action speicified");
        }
    }

    return http:FORBIDDEN;
}

isolated function isRolePermissionAvailable(int roleId, string permissionResource, string action) returns boolean|error {
    sql:ParameterizedQuery query = `
        SELECT COUNT(id) AS count FROM roles_permissions
        WHERE role_id = ${roleId}
        AND permission_id IN (SELECT id FROM permissions
                                WHERE resource = ${permissionResource} AND action = ${action})
    `;
    int count = check core:dbClient->queryRow(query);
    if (count == 1) {
        return true;
    }
    return false;
}
