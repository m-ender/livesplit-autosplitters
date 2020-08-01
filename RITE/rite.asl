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
    // This is true while the timer is running (in particular, it's false before spawning,
    // during the pause menu, while dying, and after touching the door).
    bool timerRunning: "RITE.exe", 0x4B0958, 0x0, 0x58, 0xC, 0x40;
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
    bool timerStarted = 
        current.level > 13
        && current.timerRunning 
        && !old.timerRunning
        && old.notPaused;

    if (settings["startOnEnteringLevel"]
        && current.level > 13 && current.level != old.level)
    {
        return true;
    }

    if (settings["startOnSpawning"]
        && timerStarted)
    {
        return true;
    }
}

split
{
    bool timerStarted = 
        current.level > 13
        && current.timerRunning 
        && !old.timerRunning
        && old.notPaused;

    bool timerStopped = 
        current.level > 13
        && !current.timerRunning 
        && old.timerRunning
        && current.notPaused;

    bool lastLevelInWorld = current.level % 32 == 13;

    if (settings["splitOnEnteringLevel"] 
        && current.level > 13 && current.level != old.level)
    {
        vars.DebugOutput("Splitting on entry");
        return true;
    }
    if (settings["splitOnSpawning"]
        && timerStarted)
    {
        vars.DebugOutput("Splitting on spawn");
        return true;
    }
    if (settings["splitOnLevelComplete"]
        && timerStopped && !current.isDead)
    {
        vars.DebugOutput("Splitting on level complete");
        return true;
    }
    if (settings["splitOnWorldComplete"]
        && timerStopped && !current.isDead && lastLevelInWorld)
    {
        vars.DebugOutput("Splitting on world complete");
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