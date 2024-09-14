import ballerina/sql;

type User record {|
    @sql:Column {
        name: "user_id"
    }
    int userId;
    string username;
    string email;
|};

type LoginCredentials record {|
    string username;
    string password;
|};

type UserRole record {|
    @sql:Column {
        name: "id"
    }
    int roleId;
    @sql:Column {
        name: "role_name"
    }
    string roleName;
|};

public type Project record {|
    @sql:Column {
        name: "project_id"
    }
    readonly int projectId;

    @sql:Column {
        name: "project_name"
    }
    string projectName;
    string description;

    @sql:Column {
        name: "created_date"
    }
    int createdDate;

    @sql:Column {
        name: "updated_date"
    }
    int updatedDate;

    @sql:Column {
        name: "created_by"
    }
    int createdBy;

    @sql:Column {
        name: "updated_by"
    }
    int updatedBy;
|};

type ProjectUserList record {|
    int[] userIds;
|};

public type NewProject record {|
    string projectName;
    string description;
    int userId;
|};

type Task record {|
    @sql:Column {
        name: "task_id"
    }
    int taskId;

    @sql:Column {
        name: "task_title"
    }
    string taskTitle;

    @sql:Column {
        name: "description"
    }
    string description;

    @sql:Column {
        name: "created_date"
    }
    int createdDate;

    @sql:Column {
        name: "created_by_username"
    }
    string createdByUsername;

    @sql:Column {
        name: "created_by_user_id"
    }
    int createdByUserId;
|};