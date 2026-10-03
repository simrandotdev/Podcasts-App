# Measuring Listening Activity

Count real listening time, and show a year of it as a heatmap in Settings.

## Overview

Settings opens with a Listening Activity section: a heatmap of the past year in the style of a GitHub contribution graph, and a summary of the user's listening. Three types produce it:

- term ListeningStats: Records seconds of listening per calendar day, in `UserDefaults` under `listeningSecondsByDay`.
- term ListeningHeatmap: Arranges the last 53 weeks of those totals into columns and computes the summary values.
- term SettingsViewModel: Builds the heatmap from `PlaybackManager.listeningStats`, and republishes the player's changes so the heatmap stays current while an episode plays.

### Count Listening Time

`PlaybackManager` calls `noteListeningTick(at:)` from its periodic time observer, about once a second. Each call adds the wall-clock time since the previous call, as long as all of these are true:

- The episode is playing, and isn't buffering or seeking.
- Less than 5 seconds have passed since the previous tick, so a stalled player or a suspended app doesn't add a long gap.

Because the count uses real time rather than the episode's position, 30 minutes of an episode played at 2× counts as 15 minutes of listening. Days are keyed by their date in the user's time zone, so a day matches what the user calls today.

### Draw the Heatmap

The heatmap has one column per week, oldest on the left, and one row per weekday, starting on the first day of the week for the user's locale. Days after today stay empty.

![A grid of squares shaded in five levels of orange, with a legend: no listening, 1 to 14 minutes, 15 to 29 minutes, 30 to 59 minutes, and an hour or more.](listening-heatmap)

Each day is shaded by fixed bands, defined in `ListeningHeatmap.levelThresholds`, so a color means the same amount of listening over time. Days without listening use a neutral gray. The four shades are the `Heat1` to `Heat4` colors in the asset catalog, which have separate light and dark values.

Tapping a day shows how long the user listened that day. Month names label the first column of each month, and every other weekday is labeled to keep the grid narrow.

### Summarize the Year

Above the grid, the section shows the minutes listened in the last year, and three short statistics:

- term Active days: Days with at least a minute of listening.
- term Longest streak: The most consecutive active days in the year.
- term Current streak: Consecutive active days up to today. Today doesn't break the streak until it's over.

## See Also

- <doc:Playing-Episodes>
- <doc:Configuring-Settings>
