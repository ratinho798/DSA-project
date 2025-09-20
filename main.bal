import ballerina/http;
import ballerina/log;

public type Component record {|
    string id;
    string name;
    string description?;
|};

public type Schedule record {|
    string id;
    string description;
    string nextDueDate; // ISO date as string "YYYY-MM-DD"
|};

public type WorkTask record {|
    string id;
    string description;
    string status?; // e.g. "OPEN", "DONE"
|};

public type WorkOrder record {|
    string id;
    string description;
    string status; // e.g. "OPEN", "IN_PROGRESS", "CLOSED"
    WorkTask[]? tasks;
|};

public type Asset record {|
    string assetTag;
    string name;
    string faculty;
    string department;
    string status; // "ACTIVE" | "UNDER_REPAIR" | "DISPOSED"
    string acquiredDate; // "YYYY-MM-DD"
    Component[]? components;
    Schedule[]? schedules;
    WorkOrder[]? workOrders;
|};

// The main "database" table keyed by assetTag.
public table<Asset> key(assetTag) assetDB = table [];

/*
 * VALID_STATUSES - small helper set to validate asset.status.
 */
final string[] VALID_STATUSES = ["ACTIVE", "UNDER_REPAIR", "DISPOSED"];

/*
 * Utility: check status validity
 */
function isValidStatus(string s) returns boolean {
    foreach var st in VALID_STATUSES {
        if st == s {
            return true;
        }
    }
    return false;
}

/* ===========================
   Database helper functions
   =========================== */

public function addAsset(Asset asset) returns error? {
    if !isValidStatus(asset.status) {
        return error("Invalid status: " + asset.status);
    }
    if assetDB.hasKey(asset.assetTag) {
        return error("Asset already exists with tag: " + asset.assetTag);
    }
    assetDB.add(asset);
    log:printInfo("Added asset: " + asset.assetTag);
}

public function getAsset(string tag) returns Asset|error {
    if assetDB.hasKey(tag) {
        return assetDB[tag];
    }
    return error("Asset not found: " + tag);
}

public function updateAsset(Asset asset) returns error? {
    if !isValidStatus(asset.status) {
        return error("Invalid status: " + asset.status);
    }
    if assetDB.hasKey(asset.assetTag) {
        assetDB[asset.assetTag] = asset;
        log:printInfo("Updated asset: " + asset.assetTag);
        return;
    }
    return error("Cannot update: asset not found: " + asset.assetTag);
}

public function deleteAsset(string tag) returns error? {
    if assetDB.hasKey(tag) {
        assetDB.remove(tag);
        log:printInfo("Deleted asset: " + tag);
        return;
    }
    return error("Cannot delete: asset not found: " + tag);
}

public function listAllAssets() returns Asset[] {
    Asset[] list = [];
    foreach var a in assetDB {
        list.push(a);
    }
    return list;
}

public function listAssetsByFaculty(string faculty) returns Asset[] {
    Asset[] result = [];
    foreach var a in assetDB {
        if a.faculty.toLowerAscii() == faculty.toLowerAscii() {
            result.push(a);
        }
    }
    return result;
}

public function overdueAssets(string today) returns Asset[] {
    Asset[] result = [];
    foreach var a in assetDB {
        if a.schedules is Schedule[] {
            foreach var s in a.schedules {
                if s.nextDueDate < today {
                    result.push(a);
                    break;
                }
            }
        }
    }
    return result;
}

public function addComponentToAsset(string tag, Component comp) returns error? {
    if !assetDB.hasKey(tag) {
        return error("Asset not found: " + tag);
    }
    Asset asset = assetDB[tag];
    Component[] comps = asset.components.cloneReadOnly() is Component[] ? asset.components : [];
    foreach var c in comps {
        if c.id == comp.id {
            return error("Component with id already exists: " + comp.id);
        }
    }
    comps.push(comp);
    asset.components = comps;
    assetDB[tag] = asset;
}

public function removeComponentFromAsset(string tag, string compId) returns error? {
    if !assetDB.hasKey(tag) {
        return error("Asset not found: " + tag);
    }
    Asset asset = assetDB[tag];
    if asset.components is Component[] {
        Component[] newComps = [];
        boolean found = false;
        foreach var c in asset.components {
            if c.id == compId {
                found = true;
                continue;
            }
            newComps.push(c);
        }
        if !found {
            return error("Component not found: " + compId);
        }
        asset.components = newComps;
        assetDB[tag] = asset;
        return;
    }
    return error("No components for asset: " + tag);
}

public function addScheduleToAsset(string tag, Schedule sched) returns error? {
    if !assetDB.hasKey(tag) {
        return error("Asset not found: " + tag);
    }
    Asset asset = assetDB[tag];
    Schedule[] scheds = asset.schedules.cloneReadOnly() is Schedule[] ? asset.schedules : [];
    foreach var s in scheds {
        if s.id == sched.id {
            return error("Schedule with id already exists: " + sched.id);
        }
    }
    scheds.push(sched);
    asset.schedules = scheds;
    assetDB[tag] = asset;
}

public function removeScheduleFromAsset(string tag, string schedId) returns error? {
    if !assetDB.hasKey(tag) {
        return error("Asset not found: " + tag);
    }
    Asset asset = assetDB[tag];
    if asset.schedules is Schedule[] {
        Schedule[] newScheds = [];
        boolean found = false;
        foreach var s in asset.schedules {
            if s.id == schedId {
                found = true;
                continue;
            }
            newScheds.push(s);
        }
        if !found {
            return error("Schedule not found: " + schedId);
        }
        asset.schedules = newScheds;
        assetDB[tag] = asset;
        return;
    }
    return error("No schedules for asset: " + tag);
}

/* ===========================
   Minimal service to test setup
   =========================== */

service /assets on new http:Listener(8080) {

    resource function get ping() returns json {
        return { message: "Asset service (DB) is running" };
    }

    resource function get count() returns json {
        int count = 0;
        foreach var _ in assetDB {
            count += 1;
        }
        return { count: count };
    }

    resource function post demo() returns json|error {
        Asset demo = {
            assetTag: "EQ-001",
            name: "3D Printer",
            faculty: "Computing & Informatics",
            department: "Software Engineering",
            status: "ACTIVE",
            acquiredDate: "2024-03-10",
            components: [],
            schedules: [{ id: "S1", description: "Yearly check", nextDueDate: "2025-05-01" }],
            workOrders: []
        };
        if assetDB.hasKey(demo.assetTag) {
            return { message: "Demo asset already exists", assetTag: demo.assetTag };
        }
        assetDB.add(demo);
        return { message: "Demo asset added", assetTag: demo.assetTag };
    }
}

