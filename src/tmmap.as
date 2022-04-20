[Setting category="Info" name="Enabled"]
bool enabled = false;

[Setting category="Advanced" name="Endpoint"]
string endpointUrl = "https://tm.snekw.com/api/map/update";

[Setting category="Info" name="Token" description="Token is retrieved from https://tm.snekw.com/map or from self hosted instance" password]
string token = "";

Net::HttpRequest@ PostAsync(const string &in url, const Json::Value &in data){
    auto req = Net::HttpRequest();
    req.Method = Net::HttpMethod::Post;
    req.Body = Json::Write(data);
    req.Headers['Content-Type'] = 'application/json';
    req.Headers['Authorization'] = "Token " + token;
    req.Url = url;
    req.Start();
    
    while(!req.Finished()){
        sleep(10);
    }
    return req;
}

void Main(){
	auto app = cast<CTrackMania>(GetApp());

    string currentMapUid = "";
    bool lastMapSent = false;
    bool sendingMap = false;
    bool thisErrored = false;
    int retries = 5;
    int delay = 1000;

    while(true){
        auto map = app.RootMap;

        if(enabled && map !is null && map.MapInfo.MapUid != "" && app.Editor is null){
            auto mapUid = map.MapInfo.MapUid;
            if(currentMapUid != mapUid){
                print("Map changed. (old: "+tostring(currentMapUid)+" new: " + tostring(mapUid) +")");
                currentMapUid = mapUid;
                lastMapSent = false;
                thisErrored = false;
                retries = 5;
                delay = 1000;
            }
        } else if(enabled) {
            lastMapSent = false;
            currentMapUid = "";
            thisErrored = false;
            retries = 5;
            delay = 1000;
        }

        if(enabled && currentMapUid != "" && lastMapSent == false){
            if(sendingMap == false && (thisErrored == false || retries > 0)){
                sendingMap = true;
                Json::Value data = Json::Object();
                data["mapUid"] = currentMapUid;
                data["mapName"] = tostring(StripFormatCodes(map.MapInfo.Name));
                data["mapAuthor"] = tostring(StripFormatCodes(map.MapInfo.AuthorNickName));
                data["mapAuthorTime"] = Time::Format(map.MapInfo.TMObjective_AuthorTime);
                data["mapGoldTime"] = Time::Format(map.MapInfo.TMObjective_GoldTime);
                data["mapSilverTime"] = Time::Format(map.MapInfo.TMObjective_SilverTime);
                data["mapBronzeTime"] = Time::Format(map.MapInfo.TMObjective_GoldTime);
                print("Sending map info. ("+tostring(currentMapUid)+")");
                auto result = PostAsync(endpointUrl, data);
                auto code = result.ResponseCode();
                if(code == 200){
                    auto response = result.String();
                    if(response == currentMapUid){
                        lastMapSent = true;
                        print("Map info sent. (" + tostring(response) + ")");
                    }
                } else {
                    print("Failed to send map info. ("+tostring(code)+")");
                    retries = retries - 1;
                    delay = 5000;
                    thisErrored = true;
                }
                sendingMap = false;
            }
        }

        sleep(delay);
    }
}
