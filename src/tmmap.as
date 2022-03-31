[Setting category="Info" name="Enabled"]
bool enabled = false;

[Setting category="Advanced" name="Endpoint"]
string endpointUrl = "https://tm.snekw.com/api/map/update";

[Setting category="Info" name="Token" description="Token is retrieved from https://tm.snekw.com/map or from self hosted instance"]
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
	auto network = cast<CTrackManiaNetwork>(app.Network);

    string currentMapUid = "";
    bool lastMapSent = false;
    bool sendingMap = false;

    while(true){
        auto map = app.RootMap;

        if(enabled && map !is null && map.MapInfo.MapUid != "" && app.Editor is null){
            if(currentMapUid != map.MapInfo.MapUid){

                currentMapUid = map.MapInfo.MapUid;
                lastMapSent = false;
            }
        }else if(enabled && map is null){
            lastMapSent = false;
            sendingMap = false;
            currentMapUid = "";
        }

        if(currentMapUid != "" && lastMapSent == false){
            if(sendingMap == false){
                sendingMap = true;
                Json::Value data = Json::Object();
                data["mapUid"] = currentMapUid;
                data["mapName"] = tostring(StripFormatCodes(map.MapInfo.Name));
                data["mapAuthor"] = tostring(StripFormatCodes(map.MapInfo.AuthorNickName));
                data["mapAuthorTime"] = Time::Format(map.MapInfo.TMObjective_AuthorTime);
                data["mapGoldTime"] = Time::Format(map.MapInfo.TMObjective_GoldTime);
                data["mapSilverTime"] = Time::Format(map.MapInfo.TMObjective_SilverTime);
                data["mapBronzeTime"] = Time::Format(map.MapInfo.TMObjective_GoldTime);
                auto result = PostAsync(endpointUrl, data);
                auto code = result.ResponseCode();
                if(code == 200){
                    auto response = result.String();
                    if(response == currentMapUid){
                        lastMapSent = true;
                    }
                    sendingMap = false;
                    print(response);
                }else{
                    UI::ShowNotification("SNWTMMap", "Failed to send map info. ("+tostring(code)+")");
                }
            }
        }

        sleep(1000);
    }
}
