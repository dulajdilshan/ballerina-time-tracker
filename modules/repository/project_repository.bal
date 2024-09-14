import ballerina/io;
import ballerina/sql;
import ballerina/time;
import time_tracker_2.core;

int epochValue = getEpochValue();



isolated function getAllProjects() returns Project[]|error {
    Project[] projects = [];
    // stream<Project, error?> resultStream = core:dbClient->query(`SELECT * FROM projects`);
    stream<Project, error?> resultStream = core:dbClient->query(`SELECT * FROM projects`);
    check from Project project in resultStream
        do {
            projects.push(project);
        };
    check resultStream.close();
    return projects;
}

isolated function getProjectById(int id) returns Project|error {
    sql:ParameterizedQuery query = `SELECT * FROM projects WHERE project_id = ${id}`;
    Project project = check core:dbClient->queryRow(query);
    return project;
}

isolated function addProject(NewProject newProject) returns int|error {
    int epochValue = getEpochValue();
    sql:ParameterizedQuery query = `
        INSERT INTO projects (project_name, description, created_date, created_by, updated_date, updated_by)
        VALUES (${newProject.projectName}, ${newProject.description},  
                        ${epochValue}, ${newProject.userId}, ${epochValue}, ${newProject.userId})`;
    transaction {
        sql:ExecutionResult result = check core:dbClient->execute(query);
        check commit;
        int|string? lastInsertedId = result.lastInsertId;
        if (lastInsertedId is int) {
            return lastInsertedId;
        } else {
            return error("Failed to insert the Project record");
        }
    }
}

isolated function updateProject(int projectId, NewProject newProject) returns int|error {
    int epochValue = getEpochValue();
    sql:ParameterizedQuery query = `
        UPDATE projects SET
            project_name = ${newProject.projectName},
            description = ${newProject.description},
            updated_date = ${epochValue},
            updated_by = ${newProject.userId}
        WHERE
            project_id = ${projectId}
    `;
    transaction {
        sql:ExecutionResult result = check core:dbClient->execute(query);
        check commit;
        int? affectedRows = result.affectedRowCount;
        if (affectedRows is int && affectedRows > 0) {
            return affectedRows;
        } else {
            return error("No project found with ID: " + projectId.toString());
        }
    }
}

isolated function deleteProject(int projectId) returns int|error {
    sql:ParameterizedQuery query = `
        DELETE FROM projects
        WHERE project_id = ${projectId}
    `;
    transaction {
        sql:ExecutionResult result = check core:dbClient->execute(query);
        check commit;
        int? affectedRowCount = result.affectedRowCount;
        if (affectedRowCount is int && affectedRowCount > 0) {
            return affectedRowCount;
        } else {
            return error("No project found with ID: " + projectId.toString());
        }
    }
}

isolated function getProjectUsers(int projectId) returns User[]|error {
    User[] projectUsers = [];
    sql:ParameterizedQuery query = `
        SELECT ua.userID, ua.username, ua.email
        FROM projects_users pu
                JOIN users ua ON pu.user_id = ua.userID
        WHERE pu.project_id = ${projectId};
    `;
    stream<User, error?> resultStream = core:dbClient->query(query);
    check from User user in resultStream
        do {
            projectUsers.push(user);
        };
    check resultStream.close();
    return projectUsers;
}

isolated function addUsersToProject(int projectId, int[] userIds) returns int|error {
    string[] values = [];
    foreach var user in userIds {
        values.push(string `(${projectId}, ${user})`);
    }

    string valuesString = string:'join(",", ...values);

    sql:ParameterizedQuery query = `INSERT INTO projects_users (project_id, user_id) VALUES ${valuesString}`;

    _ = check core:dbClient->execute(query);

    io:println("Query executed successfully.");

    return 1;
}

isolated function isUserInProject(int userId, int projectId) returns boolean|error {
    sql:ParameterizedQuery query = `
                    SELECT COUNT(*) FROM projects_users
                    WHERE project_id = ${projectId} AND user_id = ${userId};
                `;
    int count = check core:dbClient->queryRow(query);
    if (count == 1) {
        return true;
    }
    return false;
}

isolated function getProjectCreator(int projectId) returns User|error {
    sql:ParameterizedQuery query = `
        SELECT user_id, username, email
        FROM users 
        WHERE user_id = (SELECT created_by FROM projects WHERE project_id = ${projectId}) 
    `;
    User user = check core:dbClient->queryRow(query);
    return user;
}

isolated function getProjectTasks(int projectId) returns Task[]|error {
    Task[] projectTasks = [];
    sql:ParameterizedQuery query = `
        SELECT task_id,
            task_title,
            description,
            created_date,
            (SELECT users.username FROM users WHERE user_id = tasks.created_by) AS created_by_username,
            created_by                                                          AS created_by_user_id
        FROM tasks
        WHERE project_id = ${projectId};
    `;
    stream<Task, error?> resultStream = core:dbClient->query(query);
    check from Task task in resultStream
        do {
            projectTasks.push(task);
        };
    check resultStream.close();
    return projectTasks;
}

isolated function getEpochValue() returns int {
    return time:utcNow()[0];
}
