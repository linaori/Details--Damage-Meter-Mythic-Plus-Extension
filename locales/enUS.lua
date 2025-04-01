do
    local addonId = ...
    local languageTable = DetailsFramework.Language.RegisterLanguage(addonId, "enUS")
    local L = languageTable

    L["ADDON_MENU_ADDONS_TITLE"] = "Mythic+ Scoreboard"
    L["ADDON_MENU_ADDONS_TOOLTIP"] = "Open the Details! Mythic+ scoreboard"

    L["COMMAND_OPEN_OPTIONS"] = "Open the options"
    L["COMMAND_OPEN_OPTIONS_PRINT"] = "Opening Details! Mythic+ scoreboard options, for more information use %s"
    L["COMMAND_HELP"] = "Shows this list of commands"
    L["COMMAND_HELP_PRINT"] = "available commands"
    L["COMMAND_SHOW_VERSION"] = "Show the version in a popup"
    L["COMMAND_OPEN_SCOREBOARD"] = "Open the scoreboard"
    L["COMMAND_OPEN_LOGS"] = "Show recent logs"
    L["COMMAND_LIST_RUN_HISTORY"] = "List recent runs"
    L["COMMAND_LIST_RUN_HISTORY_NO_RUNS"] = "There are currently no saved runs"
    L["COMMAND_CLEAR_RUN_HISTORY"] = "Clear recent runs history"
    L["COMMAND_CLEAR_RUN_HISTORY_DONE"] = "Cleared the history of %s run(s)"

    L["OPTIONS_WINDOW_TITLE"] = "Details! Mythic+ Options"
    L["OPTIONS_GENERAL_OPTIONS"] = "General Options"
    L["OPTIONS_AUTO_OPEN_LABEL"] = "Automatically open scoreboard"
    L["OPTIONS_AUTO_OPEN_DESC"] = "Do you want to automatically open the scoreboard when done looting the chest, or when the run itself finishes?"
    L["OPTIONS_AUTO_OPEN_CHOICE_LOOT_CLOSED"] = "When done looting"
    L["OPTIONS_AUTO_OPEN_CHOICE_OVERALL_READY"] = "When the run ends"

    L["OPTIONS_OPEN_DELAY_LABEL"] = "Scoreboard open delay"
    L["OPTIONS_OPEN_DELAY_DESC"] = "The amount of seconds after which the scoreboard will appear according to the setting above"
    L["OPTIONS_SCOREBOARD_SCALE_LABEL"] = "Scoreboard scale"
    L["OPTIONS_SCOREBOARD_SCALE_DESC"] = "Increase or decrease the scale of the scoreboard"
    L["OPTIONS_SHOW_TOOLTIP_SUMMARY_LABEL"] = "Summary in tooltip"
    L["OPTIONS_SHOW_TOOLTIP_SUMMARY_DESC"] = "When hovering over a column in the scoreboard it will show a summary of the breakdown"
    L["OPTIONS_TRANSLIT_LABEL"] = "Translit"
    L["OPTIONS_TRANSLIT_DESC"] = "Translit Cyrillic characters to the latin alphabet"
    L["OPTIONS_SHOW_TIME_SECTIONS_LABEL"] = "Show time labels for sections"
    L["OPTIONS_SHOW_TIME_SECTIONS_DESC"] = "Shows time labels for sections on the timeline as a guide"
    L["OPTIONS_SHOW_REMAINING_TIME_LABEL"] = "Show remaining time"
    L["OPTIONS_SHOW_REMAINING_TIME_DESC"] = "When a key is timed, an extra section will be added showing the time still remaining"

    L["SCOREBOARD_NO_SCORE_AVAILABLE"] = "There is currently no score on the board"
    L["SCOREBOARD_TITLE_PLAYER_NAME"] = "Player Name"
    L["SCOREBOARD_TITLE_SCORE"] = "M+ Score"
    L["SCOREBOARD_TITLE_LOOT"] = "Loot"
    L["SCOREBOARD_TITLE_DEATHS"] = "Deaths"
    L["SCOREBOARD_TITLE_DAMAGE_TAKEN"] = "Damage Taken"
    L["SCOREBOARD_TITLE_DPS"] = "DPS"
    L["SCOREBOARD_TITLE_HPS"] = "HPS"
    L["SCOREBOARD_TITLE_INTERRUPTS"] = "Interrupts"
    L["SCOREBOARD_TITLE_DISPELS"] = "Dispels"
    L["SCOREBOARD_TITLE_CC_CASTS"] = "CC Casts"
    L["SCOREBOARD_NOT_IN_COMBAT_LABEL"] = "Not in combat"
    L["SCOREBOARD_UNKNOWN_DUNGEON_LABEL"] = "Unknown Dungeon"
    L["SCOREBOARD_TOOLTIP_OPEN_BREAKDOWN"] = "Click to open breakdown"
    L["SCOREBOARD_TOOLTIP_INTERRUPT_SUCCESS_LABEL"] = "Success"
    L["SCOREBOARD_TOOLTIP_INTERRUPT_OVERLAP_LABEL"] = "Overlap"
    L["SCOREBOARD_TOOLTIP_INTERRUPT_MISSED_LABEL"] = "Missed"
    L["SCOREBOARD_TOOLTIP_INTERRUPT_TOTAL_LABEL"] = "Total interrupts"
    L["ADDON_STARTUP_REMOVED_CORRUPT_HISTORY"] = "Removed %d corrupt run(s) from history."

    ------------------------------------------------------------
    --@localization(locale="enUS", format="lua_additive_table")@
end
