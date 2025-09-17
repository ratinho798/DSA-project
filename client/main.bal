// person5_client.bal
// Ballerina client for Asset Management System (Person 5 deliverable)
// Assumes API server is running at http://localhost:9090/assets

import ballerina/io;
import ballerina/http;
import ballerina/time;

// --- Types ---
public type Component record {
    string componentId;
    string name;
    string description?;
};

public type Schedule record {
    string scheduleId;
    string task;
    string nextDueDate; // ISO date: YYYY-MM-DD
};

public type Asset record {
    string assetTag; // unique key
    string name;
    string faculty;
    string status; // ACTIVE | UNDER_REPAIR | DISPOSED
    string nextMaintenance?; // YYYY-MM-DD
    Component[] components?;
    Schedule[] schedules?;
};

// --- Client configuration ---
final string BASE_URL = "http://localhost:9090/assets"; // change if needed
http:Client assetClient = check new (BASE_URL);

// --- High-level client functions ---

public function addAsset(Asset asset) returns error? {
    // POST /add
    http:Response resp = check assetClient->post("/add", asset);
    io:println("Add asset response status: " + resp.statusCode.toString());
    return;
}

public function updateAsset(string assetTag, Asset asset) returns error? {
    // PUT /update/{assetTag}
    http:Response resp = check assetClient->put("/update/" + assetTag, asset);
    io:println("Update asset response status: " + resp.statusCode.toString());
    return;
}

public function viewAll() returns error? {
    // GET /all
    var res = assetClient->get("/all");
    if (res is http:Response) {
        json|error j = res.getJsonPayload();
        if (j is json) {
            io:println("All assets:\n" + j.toJsonString());
        } else {
            io:println("Failed to parse response as JSON: " + j.toString());
        }
    } else {
        return res;
    }
}

public function viewByFaculty(string faculty) returns error? {
    // GET /faculty/{faculty}
    var res = assetClient->get("/faculty/" + faculty);
    if (res is http:Response) {
        json|error j = res.getJsonPayload();
        if (j is json) {
            io:println("Assets for faculty '" + faculty + "':\n" + j.toJsonString());
        }
    } else {
        return res;
    }
}

public function overdueCheck() returns error? {
    // GET /overdue
    var res = assetClient->get("/overdue");
    if (res is http:Response) {
        json|error j = res.getJsonPayload();
        if (j is json) {
            io:println("Overdue assets:\n" + j.toJsonString());
        }
    } else {
        return res;
    }
}

public function addComponentToAsset(string assetTag, Component component) returns error? {
    // POST /{assetTag}/components/add
    http:Response resp = check assetClient->post("/" + assetTag + "/components/add", component);
    io:println("Add component response status: " + resp.statusCode.toString());
    return;
}

public function addScheduleToAsset(string assetTag, Schedule schedule) returns error? {
    // POST /{assetTag}/schedules/add
    http:Response resp = check assetClient->post("/" + assetTag + "/schedules/add", schedule);
    io:println("Add schedule response status: " + resp.statusCode.toString());
    return;
}

// --- Interactive CLI helpers ---
function readLinePrompt(string prompt) returns string {
    return io:readln(prompt);
}

function buildAssetFromInput(boolean askForTag) returns Asset {
    string assetTag = askForTag ? io:readln("Asset Tag: ") : "";
    string name = io:readln("Asset Name: ");
    string faculty = io:readln("Faculty: ");
    string status = io:readln("Status (ACTIVE/UNDER_REPAIR/DISPOSED): ");
    string nextMaintenance = io:readln("Next maintenance date (YYYY-MM-DD) or leave empty: ");
    Asset asset = {
        assetTag: assetTag,
        name: name,
        faculty: faculty,
        status: status
    };
    if (nextMaintenance != "") {
        asset.nextMaintenance = nextMaintenance;
    }
    return asset;
}

// --- Demo flow used in presentation ---
public function demoFlow() returns error? {
    io:println("--- Demo flow start ---");

    // 1. Add an asset
    Asset a1 = {
        assetTag: "ASSET-1001",
        name: "Dell Latitude",
        faculty: "Engineering",
        status: "ACTIVE",
        nextMaintenance: "2025-09-01",
        components: [],
        schedules: []
    };
    check addAsset(a1);

    // 2. Update the asset
    a1.name = "Dell Latitude - Updated";
    a1.nextMaintenance = "2025-12-01";
    check updateAsset(a1.assetTag, a1);

    // 3. View all
    check viewAll();

    // 4. View by faculty
    check viewByFaculty("Engineering");

    // 5. Overdue check (depends on server logic)
    check overdueCheck();

    // 6. Add a component
    Component comp = { componentId: "C-100", name: "Battery", description: "Lithium battery" };
    check addComponentToAsset(a1.assetTag, comp);

    // 7. Add a schedule
    Schedule sched = { scheduleId: "S-100", task: "Full check", nextDueDate: "2025-11-01" };
    check addScheduleToAsset(a1.assetTag, sched);

    io:println("--- Demo flow complete ---");
    return;
}

// --- Main CLI ---
public function main() returns error? {
    io:println("Asset Management Client (Person 5)\n");
    io:println("Server base: " + BASE_URL);
    io:println("1) Add asset");
    io:println("2) Update asset");
    io:println("3) View all assets");
    io:println("4) View assets by faculty");
    io:println("5) Overdue check");
    io:println("6) Add component to asset");
    io:println("7) Add schedule to asset");
    io:println("8) Run demo flow (presentation)");
    io:println("9) Exit\n");

    while true {
        string choice = io:readln("Choose (1-9): ");
        match choice {
            "1" => {
                Asset asset = buildAssetFromInput(true);
                check addAsset(asset);
            }
            "2" => {
                string tag = io:readln("Asset Tag to update: ");
                Asset asset = buildAssetFromInput(false);
                // ensure tag is set for the payload
                asset.assetTag = tag;
                check updateAsset(tag, asset);
            }
            "3" => {
                check viewAll();
            }
            "4" => {
                string fac = io:readln("Faculty: ");
                check viewByFaculty(fac);
            }
            "5" => {
                check overdueCheck();
            }
            "6" => {
                string tag = io:readln("Asset Tag: ");
                Component comp = { componentId: io:readln("Component ID: "), name: io:readln("Name: ") };
                comp.description = io:readln("Description (optional): ");
                check addComponentToAsset(tag, comp);
            }
            "7" => {
                string tag = io:readln("Asset Tag: ");
                Schedule s = { scheduleId: io:readln("Schedule ID: "), task: io:readln("Task: "), nextDueDate: io:readln("Next Due Date (YYYY-MM-DD): ") };
                check addScheduleToAsset(tag, s);
            }
            "8" => {
                check demoFlow();
            }
            "9" => {
                io:println("Goodbye");
                break;
            }
            _ => {
                io:println("Invalid choice");
            }
        }
    }
}