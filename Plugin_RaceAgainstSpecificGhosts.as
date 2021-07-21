#name "RaceAgainstSpecificGhosts"
#author "https://openplanet.nl/u/banjee, Discord user Ties0017#0017, malon, Discord user 100480922406653952"
#category "Race"
#perms "full"
//v1.2

#include "Formatting.as"
#include "Time.as"
#include "Icons.as"

class GhostInfo {
    string driverName;
    uint time;
    MwId instance;
}

string name = "";
string inputUrl = "";
string savedMessage = "";
bool urlSent = false;
bool removeGhost = false;
bool windowVisible = false;
CGameGhostScript@ ghost;
MwId ghostInstance;
GhostInfo ghostToRemove;
int indexToRemove;
array<GhostInfo@> ghostList;

void log(string msg)
{
    print("[\\$9cf" + name + "\\$fff] " + msg);
}

void AddTimeString(int time, string colorCode = "\\$z")
{
    if (time > 0)
    {
        UI::Text(colorCode + Time::Format(time));
    }
    else
    {
        UI::Text(colorCode + "-:--.---");
    }
}

void RenderMenu()
{
    if (UI::MenuItem("\\$999" + Icons::Download + "\\$z Race Against Specifc Ghost", "", windowVisible) && !windowVisible)
    {
        windowVisible = !windowVisible;
    }
}

void RenderInterface()
{
    if (windowVisible)
    {
        UI::Begin("Race Against Specifc Ghost", windowVisible, UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize);

        CTrackMania@ app = cast<CTrackMania>(GetApp());
        if (app.RootMap !is null)
        {
            UI::Text("Paste the URL of the Specific Ghost from trackmania.io below");
            UI::Text("or paste the path of a downloaded Replay.Gbx file.");
            inputUrl = UI::InputText("Ghost URL", inputUrl);
            if (!urlSent && UI::Button("Load Specific Ghost"))
            {
                urlSent = true;
            }

            if(!ghostList.IsEmpty()){
                UI::Columns(3, "replays");

                UI::Text("Nickname"); UI::NextColumn();
                UI::Text("Time"); UI::NextColumn();
                UI::Text("Remove"); UI::NextColumn();
                UI::Separator();
                for(int i = 0; i < ghostList.get_Length(); i++){
                    auto info = ghostList[i];
                    UI::Text(info.driverName);
                    UI::NextColumn();
                    AddTimeString(info.time);
                    UI::NextColumn();
                    if(UI::Button("Remove Ghost")){
                        removeGhost = true;
                        ghostToRemove = info;
                        indexToRemove = i;
                    }
                    UI::NextColumn();
                    UI::Separator();
                } 
            }
            

            if (savedMessage != "")
            {
                UI::Text(savedMessage);
            }
        }
        else
        {
            UI::Text("Play the track you want to combine the ghost(s) with");
            savedMessage = "";
        }

        UI::End();
    }
}

CGameDataFileManagerScript@ TryGetDataFileMgr()
{
    CTrackMania@ app = cast<CTrackMania>(GetApp());
    if (app !is null)
    {
        CSmArenaRulesMode@ playgroundScript = cast<CSmArenaRulesMode>(app.PlaygroundScript);
        if (playgroundScript !is null)
        {
            CGameDataFileManagerScript@ dataFileMgr = cast<CGameDataFileManagerScript>(playgroundScript.DataFileMgr);
            if (dataFileMgr !is null)
            {
                return dataFileMgr;
            }
        }
    }
    return null;
}

CSmArenaRulesMode@ getPGS() {
    auto app = cast<CTrackMania@>(GetApp());
    return cast<CSmArenaRulesMode@>(app.PlaygroundScript);
}

void getGhostFromDisk(){
    log("File Found, opening...");

    auto dataFileMgr = TryGetDataFileMgr();

    CWebServicesTaskResult_GhostListScript@ ghosts = dataFileMgr.Replay_Load(inputUrl);
    if(ghosts.Ghosts[0] !is null){
        @ghost = ghosts.Ghosts[0];
    }
}

void getGhostFromWeb(){
    log("Download triggered for " + inputUrl);

    auto dataFileMgr = TryGetDataFileMgr();
    CTrackMania@ app = cast<CTrackMania>(GetApp());

    if (dataFileMgr !is null && app.RootMap !is null && inputUrl != "")
    {
        CWebServicesTaskResult_GhostScript@ result = dataFileMgr.Ghost_Download("", inputUrl);
        uint timeout = 20000;
        uint currentTime = 0;
        while (result.Ghost is null && currentTime < timeout)
        {
            currentTime += 100;
            sleep(100);
        }
        CGameGhostScript@ tempGhost = cast<CGameGhostScript>(result.Ghost);
        if (tempGhost !is null)
        {
            @ghost = tempGhost;
        }
        else
        {
            log("Download Failed");
        }
    }
    else
    {
        log("Error: dataFileMgr was null, app.RootMap was null, or inputUrl was emptyString");
    }
}

void Main()
{
    name = Meta::ExecutingPlugin().Name;
    log("Initializing");

    while (true)
    {
        CSmArenaClient@ playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);
		if(playground is null){
            while(!ghostList.IsEmpty()){
                ghostList.RemoveLast();
            }
        }
        if (urlSent)
        {
            if (IO::FileExists(inputUrl)){
                getGhostFromDisk();
            }else{
                getGhostFromWeb();
            }

            if(ghost !is null){
                auto pgs = getPGS();
                ghostInstance = pgs.Ghost_Add(ghost, true);
                GhostInfo@ gi = GhostInfo();
                gi.driverName = ghost.Nickname;
                gi.time = ghost.Result.Time;
                gi.instance = ghostInstance;

                ghostList.InsertLast(gi);

                inputUrl = "";
                urlSent = false;
                savedMessage = "";
                log("Ghost Loaded Successfully.");

            } else {
                log("Ghost Loading went wrong.");
            }
            
        }
        if(removeGhost){
            log("Removing Ghost.");

            auto pgs = getPGS();
            if (pgs !is null) {
                pgs.Ghost_Remove(ghostToRemove.instance);
                ghostList.RemoveAt(indexToRemove);
            }
            removeGhost = false;
        }
        sleep(1000);
    }
}
