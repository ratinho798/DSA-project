import ballerina/http;
import ballerina/time;
import ballerina/log;

// ===== Entity Types =====
public type Component record {|
    string componentId;
    string name;
    string description?;
|};

public type Schedule record {|
    string scheduleId;
    string task;
    string nextDueDate; // ISO format YYYY-MM-DD
|};

public type Asset record {|
    readonly string assetTag;
    string name;
    string faculty;
    string status; // "ACTIVE" | "UNDER_REPAIR" | "DISPOSED"
    string nextMaintenance?;
    Component[]? components;
    Schedule[]? schedules;
|};

// ===== Table Database =====
table<Asset> key(assetTag) assets = table [];

final string[] VALID_STATUSES = ["ACTIVE", "UNDER_REPAIR", "DISPOSED"];

// ===== Helper Functions =====
function isValidStatus(string s) returns boolean {
    foreach var status in VALID_STATUSES {
        if status == s {
            return true;
        }
    }
    return false;
}

// ===== Service =====
service /assets on new http:Listener(9090) {

    resource function get ping() returns json {
        return { message: "Asset Service Running" };
    }

    // Create Asset
    resource function post .(Asset newAsset) returns http:Response|error {
        http:Response resp = new;

        if assets.hasKey(newAsset.assetTag) {
            resp.statusCode = 400;
            resp.setPayload({ message: "Asset tag already exists!" });
            return resp;
        }

        if !isValidStatus(newAsset.status) {
            resp.statusCode = 400;
            resp.setPayload({ message: "Invalid status!" });
            return resp;
        }

        assets.add(newAsset);
        log:printInfo("Added asset: " + newAsset.assetTag);
        resp.statusCode = 201;
        resp.setPayload({ message: "Asset added successfully", asset: newAsset });
        return resp;
    }

    // Update Asset
    resource function put update/[string assetTag](Asset updatedAsset) returns http:Response|error {
        http:Response resp = new;

        if !assets.hasKey(assetTag) {
            resp.statusCode = 404;
            resp.setPayload({ message: "Asset not found!" });
            return resp;
        }

        if !isValidStatus(updatedAsset.status) {
            resp.statusCode = 400;
            resp.setPayload({ message: "Invalid status!" });
            return resp;
        }

        // Remove old record and add updated one
        _ = assets.remove(assetTag);
        assets.add(updatedAsset);
        resp.statusCode = 200;
        resp.setPayload({ message: "Asset updated successfully", asset: updatedAsset });
        return resp;
    }

    // Search Asset by Tag
    resource function get search/[string assetTag]() returns http:Response|error {
        http:Response resp = new;
        if assets.hasKey(assetTag) {
            resp.statusCode = 200;
            resp.setPayload(assets.get(assetTag));
        } else {
            resp.statusCode = 404;
            resp.setPayload({ message: "Asset not found!" });
        }
        return resp;
    }

    // Delete Asset
    resource function delete remove/[string assetTag]() returns http:Response|error {
        http:Response resp = new;
        if assets.hasKey(assetTag) {
            _ = assets.remove(assetTag);
            resp.statusCode = 200;
            resp.setPayload({ message: "Asset deleted successfully" });
        } else {
            resp.statusCode = 404;
            resp.setPayload({ message: "Asset not found!" });
        }
        return resp;
    }

    // View All Assets
    resource function get .() returns Asset[]|error {
        return from var asset in assets
            select asset;
    }

    // View Assets by Faculty
    resource function get faculty/[string facultyName]() returns Asset[]|error {
        return from var asset in assets
            where asset.faculty.toLowerAscii() == facultyName.toLowerAscii()
            select asset;
    }

    // Overdue Assets
    resource function get overdue() returns Asset[]|error {
        time:Utc now = time:utcNow();
        string today = time:utcToString(now).substring(0, 10);

        Asset[] result = [];
        foreach var asset in assets {
            foreach var s in asset.schedules ?: [] {
                if s.nextDueDate < today {
                    result.push(asset);
                    break;
                }
            }
        }
        return result;
    }

    // Add Component
    resource function post [string assetTag]/components/add(Component comp) returns http:Response|error {
        http:Response resp = new;

        if !assets.hasKey(assetTag) {
            resp.statusCode = 404;
            resp.setPayload({ message: "Asset not found!" });
            return resp;
        }

        Asset asset = assets.get(assetTag);
        Component[] comps = asset.components ?: [];
        foreach var c in comps {
            if c.componentId == comp.componentId {
                resp.statusCode = 400;
                resp.setPayload({ message: "Component with same id already exists!" });
                return resp;
            }
        }
        comps.push(comp);
        
        // Create updated asset with new components
        Asset updatedAsset = {
            assetTag: asset.assetTag,
            name: asset.name,
            faculty: asset.faculty,
            status: asset.status,
            nextMaintenance: asset.nextMaintenance,
            components: comps,
            schedules: asset.schedules
        };
        
        // Update the table
        _ = assets.remove(assetTag);
        assets.add(updatedAsset);

        resp.statusCode = 201;
        resp.setPayload({ message: "Component added", asset: updatedAsset });
        return resp;
    }

    // Add Schedule
    resource function post [string assetTag]/schedules/add(Schedule sched) returns http:Response|error {
        http:Response resp = new;

        if !assets.hasKey(assetTag) {
            resp.statusCode = 404;
            resp.setPayload({ message: "Asset not found!" });
            return resp;
        }

        Asset asset = assets.get(assetTag);
        Schedule[] scheds = asset.schedules ?: [];
        foreach var s in scheds {
            if s.scheduleId == sched.scheduleId {
                resp.statusCode = 400;
                resp.setPayload({ message: "Schedule with same id already exists!" });
                return resp;
            }
        }
        scheds.push(sched);
        
        // Create updated asset with new schedules
        Asset updatedAsset = {
            assetTag: asset.assetTag,
            name: asset.name,
            faculty: asset.faculty,
            status: asset.status,
            nextMaintenance: asset.nextMaintenance,
            components: asset.components,
            schedules: scheds
        };
        
        // Update the table
        _ = assets.remove(assetTag);
        assets.add(updatedAsset);

        resp.statusCode = 201;
        resp.setPayload({ message: "Schedule added", asset: updatedAsset });
        return resp;
    }
}