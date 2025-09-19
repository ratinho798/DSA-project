import ballerina/io;
import ballerina/http;

final string BASE_URL = "http://localhost:9090/assets";
http:Client assetClient = check new(BASE_URL);

public type Component record {|
    string componentId;
    string name;
    string description?;
|};

public type Schedule record {|
    string scheduleId;
    string task;
    string nextDueDate;
|};

public type Asset record {|
    string assetTag;
    string name;
    string faculty;
    string status;
    string nextMaintenance?;
    Component[]? components;
    Schedule[]? schedules;
|};

public function main() returns error? {
    io:println("Asset Management Client\nServer base: " + BASE_URL);

    while true {
        io:println("\n1) Add asset\n2) Update asset\n3) Search asset by tag\n4) Delete asset");
        io:println("5) View all assets\n6) View by faculty\n7) Overdue check\n8) Add component\n9) Add schedule\n10) Exit");
        string choice = io:readln("Choose (1-10): ");
        
        match choice {
            "1" => {
                // Add Asset
                string tag = io:readln("Asset Tag: ");
                string name = io:readln("Name: ");
                string faculty = io:readln("Faculty: ");
                string status = io:readln("Status (ACTIVE/UNDER_REPAIR/DISPOSED): ");
                Asset asset = { assetTag: tag, name: name, faculty: faculty, status: status, components: [], schedules: [] };
                http:Response|error res = assetClient->post("/", asset);
                if res is error {
                    io:println("Error: " + res.message());
                } else {
                    io:println("Response: " + res.statusCode.toString());
                    io:println(res.getJsonPayload());
                }
            }
            "2" => {
                // Update Asset
                string tag = io:readln("Asset Tag to update: ");
                string name = io:readln("Name: ");
                string faculty = io:readln("Faculty: ");
                string status = io:readln("Status (ACTIVE/UNDER_REPAIR/DISPOSED): ");
                Asset asset = { assetTag: tag, name: name, faculty: faculty, status: status, components: [], schedules: [] };
                http:Response|error res = assetClient->put("/update/" + tag, asset);
                if res is error {
                    io:println("Error: " + res.message());
                } else {
                    io:println("Response: " + res.statusCode.toString());
                    io:println(res.getJsonPayload());
                }
            }
            "3" => {
                // Search Asset by Tag
                string tag = io:readln("Asset Tag to search: ");
                http:Response|error res = assetClient->get("/search/" + tag);
                if res is error {
                    io:println("Error: " + res.message());
                } else {
                    io:println("Response: " + res.statusCode.toString());
                    io:println(res.getJsonPayload());
                }
            }
            "4" => {
                // Delete Asset
                string tag = io:readln("Asset Tag to delete: ");
                http:Response|error res = assetClient->delete("/remove/" + tag);
                if res is error {
                    io:println("Error: " + res.message());
                } else {
                    io:println("Response: " + res.statusCode.toString());
                    io:println(res.getJsonPayload());
                }
            }
            "5" => {
                // View All Assets
                http:Response|error res = assetClient->get("/");
                if res is error {
                    io:println("Error: " + res.message());
                } else {
                    io:println("Response: " + res.statusCode.toString());
                    io:println(res.getJsonPayload());
                }
            }
            "6" => {
                // View by Faculty
                string faculty = io:readln("Faculty name: ");
                http:Response|error res = assetClient->get("/faculty/" + faculty);
                if res is error {
                    io:println("Error: " + res.message());
                } else {
                    io:println("Response: " + res.statusCode.toString());
                    io:println(res.getJsonPayload());
                }
            }
            "7" => {
                // Overdue Check
                http:Response|error res = assetClient->get("/overdue");
                if res is error {
                    io:println("Error: " + res.message());
                } else {
                    io:println("Response: " + res.statusCode.toString());
                    io:println(res.getJsonPayload());
                }
            }
            "8" => {
                // Add Component
                string tag = io:readln("Asset Tag: ");
                string compId = io:readln("Component ID: ");
                string compName = io:readln("Component Name: ");
                string compDesc = io:readln("Component Description: ");
                Component comp = { componentId: compId, name: compName, description: compDesc };
                http:Response|error res = assetClient->post("/" + tag + "/components/add", comp);
                if res is error {
                    io:println("Error: " + res.message());
                } else {
                    io:println("Response: " + res.statusCode.toString());
                    io:println(res.getJsonPayload());
                }
            }
            "9" => {
                // Add Schedule
                string tag = io:readln("Asset Tag: ");
                string schedId = io:readln("Schedule ID: ");
                string task = io:readln("Task: ");
                string dueDate = io:readln("Due Date (YYYY-MM-DD): ");
                Schedule sched = { scheduleId: schedId, task: task, nextDueDate: dueDate };
                http:Response|error res = assetClient->post("/" + tag + "/schedules/add", sched);
                if res is error {
                    io:println("Error: " + res.message());
                } else {
                    io:println("Response: " + res.statusCode.toString());
                    io:println(res.getJsonPayload());
                }
            }
            "10" => {
                io:println("Goodbye!");
                break;
            }
            _ => {
                io:println("Invalid choice! Please try again.");
            }
        }
    }
}