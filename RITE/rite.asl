state("RITE", "Patch 01 (Steam)")
{
    // The screen number. Splash screen, main menu, credits, each world etc all have
    // separate numbers. The levels start at 14 and appear to be all consecutively
    // numbered, so we can obtain the current level by subtracting 13 from this.
    int level : "RITE.exe", 0x6C2DB8;
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
    // This is only 0 while the pause menu is open, and 1 otherwise.
    bool notPaused : "RITE.exe", 0x3FEA04;
    // This is only true during the death animation. Adding C  to the final offset 
    // gives another such byte.
    bool isDying : "RITE.exe", 0x4B0958, 0x0, 0x78, 0xC, 0x40;
    // This is true while the timer is running (in particular, it's false before spawning,
    // during the pause menu, while dying, and after touching the door).
    bool timerRunning: "RITE.exe", 0x4B0958, 0x0, 0x58, 0xC, 0x40;
    // Number of coins collected in the current level. Replacing the first offset 
    // with 0x4B27F8 also works.
    double coins : "RITE.exe", 0x4B2780, 0x2C, 0x10, 0x294, 0x0;
    // Coins available in the current level.
    double maxCoins : "RITE.exe", 0x4B2780, 0x2C, 0x10, 0x1E0, 0x0;
}

state("RITE", "Patch 03 (Steam)")
{
    // The screen number. Splash screen, main menu, credits, each world etc all have
    // separate numbers. The levels start at 14 and appear to be all consecutively
    // numbered, so we can obtain the current level by subtracting 13 from this.
    int level : "RITE.exe", 0x12C680, 0x4;
    // This is only 1 while the pause menu is open, and 0 otherwise.
    // Couldn't find notPaused value directly, so this is used to determine notPaused in update.
    bool paused : "RITE.exe", 0x6F6E38, 0x94;
    // This is only true during the death animation.
    bool isDying : "RITE.exe", 0x4E48F4, 0x0, 0x12C, 0x2C, 0xAC0;
    // This is true while the timer is running (in particular, it's false before spawning,
    // during the pause menu, while dying, and after touching the door).
    bool timerRunning: "RITE.exe", 0x4E48E4, 0x120, 0x40;
    // Number of coins collected in the current level.
    double coins : "RITE.exe", 0x704B88, 0x30, 0xFC, 0x160;
    // Coins available in the current level.
    double maxCoins : "RITE.exe", 0x704B88, 0x30, 0x45C, 0x130;
}

state("RITE", "Minor update after Patch 03 (Steam)")
{
    // The screen number. Splash screen, main menu, credits, each world etc all have
    // separate numbers. The levels start at 14 and appear to be all consecutively
    // numbered, so we can obtain the current level by subtracting 13 from this.
    int level : "RITE.exe", 0x8B27C8;
    // This is only 1 while the pause menu is open, and 0 otherwise.
    // Couldn't find notPaused value directly, so this is used to determine notPaused in update.
    bool paused : "RITE.exe", 0x5F4524;
    // This is only true during the death animation.
    bool isDying : "RITE.exe", 0x0069FA98, 0x0, 0x210, 0x18, 0x878;
    // This is true while the timer is running (in particular, it's false before spawning,
    // during the pause menu, while dying, and after touching the door).
    bool timerRunning: "RITE.exe", 0x0069FA98, 0x0, 0x1B0, 0x18, 0x78;
    // Number of coins collected in the current level.
    double coins : "RITE.exe", 0x008C2008, 0x30, 0xF0, 0x130;
    // Coins available in the current level.
    double maxCoins : "RITE.exe", 0x008C2008, 0x30, 0xF0, 0x140;
}

startup
{
    settings.Add("startOnEnteringLevel", false, "Start when entering a level");
    settings.Add("startOnSpawning", true, "Start when spawning");
    settings.Add("splitOnEnteringLevel", false, "Split when entering a level");
    settings.Add("splitOnSpawning", false, "Split when spawning");
    settings.Add("splitOnLevelComplete", false, "Split when completing a level");
        settings.Add("splitOnlyWith20Coins", false, "Only split if all coins were collected", "splitOnLevelComplete");
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
    vars.DebugOutput(moduleSize.ToString());
    // TODO: distinguish between patch 01 and 02? Module size is the same.
    switch (moduleSize)
    {
    case 7593984:
        version = "Patch 02 (Steam)";
        break;
    case 7675904:
        version = "Patch 03 (Steam)";
        break;
    case 9789440:
        version = "Minor update after Patch 03 (Steam)";
        break;
    }
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
        : false;

    // Sets notPaused using paused for Patch 03.
    if (((IDictionary<String, object>)current).ContainsKey("paused"))
        current.notPaused = !current.paused;

    if (current.isDying && !old.isDying)
        current.isDead = true;

    if (current.isDead && current.timerRunning && !old.timerRunning)
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
        current.isDead = false;
        return true;
    }

    if (settings["startOnSpawning"]
        && timerStarted)
    {
        current.isDead = false;
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
        if (!settings["splitOnlyWith20Coins"] || old.coins == current.maxCoins)
        {
            vars.DebugOutput("Splitting on level complete");
            return true;
        }
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