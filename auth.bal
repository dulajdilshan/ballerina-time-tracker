import time_tracker_2.core;

service /api/auth on core:httpListner {
    resource function get . () returns string {
        return "Hello Auth";
    }
}
