import ballerina/http;

type Asset record {|
    string assetTag;
    string name;
    string status;
|};

// In-memory store for assets
map<Asset> assets = {};

// Listener endpoint
listener http:Listener assetListener = new (8080);

service /assets on assetListener {

    // This Add Asset
    resource function post add(Asset newAsset) returns http:Response|error {
        http:Response resp = new;

        // Validation: no duplicate tags
        if assets.hasKey(newAsset.assetTag) {
            resp.statusCode = 400;
            resp.setPayload({ message: "Asset tag already exists!" });
            return resp;
        }

        // Validation: check status
        if !(newAsset.status in ["ACTIVE", "UNDER_REPAIR", "DISPOSED"]) {
            resp.statusCode = 400;
            resp.setPayload({ message: "Invalid status!" });
            return resp;
        }

        assets[newAsset.assetTag] = newAsset;
        resp.statusCode = 201;
        resp.setPayload({ message: "Asset added successfully", asset: newAsset });
        return resp;
    }

    // Update Asset
    resource function put update(string assetTag, Asset updatedAsset) returns http:Response|error {
        http:Response resp = new;

        if !assets.hasKey(assetTag) {
            resp.statusCode = 404;
            resp.setPayload({ message: "Asset not found!" });
            return resp;
        }

        if !(updatedAsset.status in ["ACTIVE", "UNDER_REPAIR", "DISPOSED"]) {
            resp.statusCode = 400;
            resp.setPayload({ message: "Invalid status!" });
            return resp;
        }

        assets[assetTag] = updatedAsset;
        resp.statusCode = 200;
        resp.setPayload({ message: "Asset updated successfully", asset: updatedAsset });
        return resp;
    }

    // enables Search Asset by Tag
    resource function get search(string assetTag) returns http:Response|error {
        http:Response resp = new;

        if assets.hasKey(assetTag) {
            resp.statusCode = 200;
            resp.setPayload(assets[assetTag]);
        } else {
            resp.statusCode = 404;
            resp.setPayload({ message: "Asset not found!" });
        }

        return resp;
    }

    // Delete's Asset
    resource function delete remove(string assetTag) returns http:Response|error {
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
}
