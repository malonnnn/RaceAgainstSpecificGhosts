#name "RaceAgainstSpecificGhosts"
#author "https://openplanet.nl/u/banjee, malon, Discord user Ties0017#0017"
#category "Race"
#perms "paid"

#include "Formatting.as"
#include "Time.as"
#include "Icons.as"

string name = "";
string inputUrl = "";
string savedMessage = "";
bool urlSent = false;
bool windowVisible = false;

void log(string msg)
{
    print("[\\$9cf" + name + "\\$fff] " + msg);
}

void RenderMenu()
{
    if (UI::MenuItem("\\$999" + Icons::Download + "\\$z Ghost to Race", "", windowVisible) && !windowVisible)
    {
        windowVisible = !windowVisible;
    }
}

void RenderInterface()
{
    if (windowVisible)
    {
        UI::Begin("Ghost To Race", windowVisible, UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize);

        CTrackMania@ app = cast<CTrackMania>(GetApp());
        if (app.RootMap !is null)
        {
            UI::Text("Enter URL for the Ghost");
            inputUrl = UI::InputText("Ghost URL", inputUrl);
            UI::Text("\\$f99WARNING:\\$ccc An invalid URL will result in the game crashing");
            if (!urlSent && UI::Button("Race"))
            {
                urlSent = true;
            }
            if (savedMessage != "")
            {
                UI::Text(savedMessage);
            }
        }
        else
        {
            UI::Text("Play the track you want to combine the ghost with");
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

void Main()
{
    name = Meta::ExecutingPlugin().Name;
    log("Initializing");

    while (true)
    {
        if (urlSent)
        {
            auto dataFileMgr = TryGetDataFileMgr();
            CTrackMania@ app = cast<CTrackMania>(GetApp());
            if (IO::FileExists(inputUrl)){
                CWebServicesTaskResult_GhostListScript@ ghosts = dataFileMgr.Replay_Load(inputUrl);
                auto singleGhost = ghosts.Ghosts[0];
                auto pgs = getPGS();
                pgs.Ghost_Add(singleGhost, true);
            }else{
                log("Download triggered for " + inputUrl);
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
                    CGameGhostScript@ ghost = cast<CGameGhostScript>(result.Ghost);
                    if (ghost !is null)
                    {
                        auto pgs = getPGS();
                        pgs.Ghost_Add(ghost, true);
                    }
                    else
                    {
                        log("Download Failed");
                    }
                }
                else
                {
                    log("Failed");
                }
            }
            inputUrl = "";
            urlSent = false;
            savedMessage = "";
        }
        sleep(1000);
    }
}
