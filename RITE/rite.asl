state("RITE", "Patch 01 (Steam)")
{
    // The screen number. Splash screen, main menu, credits, each world etc all have
    // separate numbers. The levels start at 14 and appear to be all consecutively
    // numbered, so we can obtain the current level by subtracting 13 from this.
    int level : "RITE.exe", 0x6C2DB8;
    // This is true on any screen where the player can't control the Nim, i.e. pause
    // menu, door menu, level select, main menu etc. It's also briefly true while
    // the menu background comes up during resets.
    bool menuActive : "RITE.exe", 0x6C5160;
    // This is only 0 while the pause menu is open, and 1 otherwise.
    bool notPaused : "RITE.exe", 0x3FEA04;
    // This is only true during the death animation. Adding C  to the final offset 
    // gives another such byte.
    bool isDying : "RITE.exe", 0x4B0958, 0x0, 0x78, 0xC, 0x40;
}

state("RITE", "Patch 02 (Steam)")
{
    // The screen number. Splash screen, main menu, credits, each world etc all have
    // separate numbers. The levels start at 14 and appear to be all consecutively
    // numbered, so we can obtain the current level by subtracting 13 from this.
    int level : "RITE.exe", 0x6C2DB8;
    // This is true on any screen where the player can't control the Nim, i.e. pause
    // menu, door menu, level select, main menu etc. It's also briefly true while
    // the menu background comes up during resets.
    bool menuActive : "RITE.exe", 0x6C5160;
    // This is only 0 while the pause menu is open, and 1 otherwise.
    bool notPaused : "RITE.exe", 0x3FEA04;
    // This is only true during the death animation. Adding C  to the final offset 
    // gives another such byte.
    bool isDying : "RITE.exe", 0x4B0958, 0x0, 0x78, 0xC, 0x40;
}

startup
{
    settings.Add("startOnEnteringLevel", false, "Start when entering a level");
    settings.Add("startOnSpawning", true, "Start when spawning");
    settings.Add("splitOnEnteringLevel", false, "Split when entering a level");
    settings.Add("splitOnSpawning", false, "Split when spawning");
    settings.Add("splitOnLevelComplete", false, "Split when completing a level");
    settings.Add("splitOnWorldComplete", true, "Split when completing the last level of a world");
    settings.Add("resetOnWorld1Menu", false, "Reset when entering the world 1 level select");
    settings.Add("resetOnDeath", false, "Reset on death (useful for IL runs)");

    Action<string> DebugOutput = (text) => {
        print("[RITE Autosplitter] "+text);
    };
    vars.DebugOutput = DebugOutput;
}

init
{
    int moduleSize = modules.First().ModuleMemorySize;
    // TODO: distinguish between patch 01 and 02? Module size is the same.
    switch (moduleSize)
    {
    case 7593984:
        version = "Patch 02 (Steam)";
        break;
    }
 
    current.isDead = true;
}

exit
{
    timer.IsGameTimePaused = true;
}

update
{
    if (version == "")
        return false;

    // TODO: Is there a cleaner way to store persistent state? Vars maybe?
    current.isDead = ((IDictionary<String, object>)old).ContainsKey("isDead") 
        ? old.isDead 
        : true;

    if (current.isDying && !old.isDying)
        current.isDead = true;

    if (current.isDead && !current.menuActive && old.menuActive)
        current.isDead = false;
}

start
{
    if (settings["startOnEnteringLevel"]
        && current.level > 13 && current.level != old.level)
    {
        return true;
    }
    if (settings["startOnSpawning"]
        && current.level > 13 && old.menuActive && !current.menuActive)
    {
        return true;
    }
}

split
{
    bool justOpenedDoorMenu = 
        current.level > 13
        && current.menuActive 
        && !old.menuActive 
        && current.notPaused
        && !current.isDead;

    bool lastLevelInWorld = current.level % 32 == 13;

    if (settings["splitOnEnteringLevel"] 
        && current.level > 13 && current.level != old.level)
    {
        return true;
    }
    if (settings["splitOnSpawning"]
        && old.menuActive && !current.menuActive && !old.isDead)
    {
        return true;
    }
    if (settings["splitOnLevelComplete"]
        && justOpenedDoorMenu)
    {
        return true;
    }
    if (settings["splitOnWorldComplete"]
        && justOpenedDoorMenu && lastLevelInWorld)
    {
        return true;
    }
}

reset
{
    if (settings["resetOnWorld1Menu"]
        && current.level == 5 && old.level != current.level)
        return true;

    if (settings["resetOnDeath"]
        && current.isDying && !old.isDying)
        return true;
}