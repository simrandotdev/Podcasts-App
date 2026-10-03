#!/usr/bin/env python3
"""Draws the block diagrams in the On Air documentation.

Each diagram is written twice to ../OnAir.docc/Resources: `<name>.svg` for light appearance and
`<name>~dark.svg` for dark appearance. DocC shows whichever one matches the reader's appearance.

Run it after changing a diagram:

    python3 Docs/iOS/Diagrams/generate_diagrams.py

It uses only the standard library. SVG can't measure or wrap text, so the script estimates the
width of every label and warns when one probably overflows its box.
"""

from __future__ import annotations

import math
import pathlib
import sys
from xml.sax.saxutils import escape

OUTPUT = pathlib.Path(__file__).resolve().parent.parent / "OnAir.docc" / "Resources"

SANS = "-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', Helvetica, Arial, sans-serif"
MONO = "ui-monospace, 'SF Mono', SFMono-Regular, Menlo, Consolas, monospace"

THEMES = ("light", "dark")

# Fill and stroke of each tone, per appearance.
TONES = {
    "light": {
        "neutral": ("#f5f5f7", "#c7c7cc"),
        "blue": ("#ebf4ff", "#0071e3"),
        "purple": ("#f6effc", "#a64fd9"),
        "green": ("#ecf8f0", "#248a3d"),
        "orange": ("#fff4e6", "#c96a00"),
        "teal": ("#e9f7f9", "#0b8799"),
        "red": ("#fdeeee", "#d70015"),
        "gray": ("#f2f2f5", "#8e8e93"),
    },
    "dark": {
        "neutral": ("#2c2c2e", "#545458"),
        "blue": ("#0d2742", "#409cff"),
        "purple": ("#2c1b3b", "#bf5af2"),
        "green": ("#0f2f1b", "#30d158"),
        "orange": ("#3b2509", "#ff9f0a"),
        "teal": ("#072e33", "#40c8e0"),
        "red": ("#3b1113", "#ff453a"),
        "gray": ("#1f1f21", "#8e8e93"),
    },
}
INK = {
    "light": {"text": "#1d1d1f", "secondary": "#6e6e73", "line": "#6e6e73"},
    "dark": {"text": "#f5f5f7", "secondary": "#a1a1a6", "line": "#a1a1a6"},
}
SURFACE = {"light": "#ffffff", "dark": "#1c1c1e"}
# The app's Heat1–Heat4 colors, after an empty-day gray (systemGray5).
HEAT = {
    "light": ["#e5e5ea", "#f2a65e", "#e07e26", "#c45500", "#8a3b00"],
    "dark": ["#2c2c2e", "#844110", "#ac5313", "#e2701a", "#ffa552"],
}


def text_width(text: str, size: float, mono: bool = False, bold: bool = False) -> float:
    """A generous estimate of rendered width, in points."""
    if mono:
        return len(text) * size * 0.6
    total = 0.0
    for ch in text:
        if ch in "iljI.,:;'|!()[] ":
            total += 0.3
        elif ch in "mwMW":
            total += 0.85
        elif ch.isupper() or ch == "…":
            total += 0.68
        elif ch.isdigit():
            total += 0.58
        else:
            total += 0.54
    return total * size * (1.07 if bold else 1)


def rounded_path(points, radius=8.0) -> str:
    """A path through `points` with rounded corners."""
    d = f"M{points[0][0]:g} {points[0][1]:g}"
    for i in range(1, len(points) - 1):
        (x0, y0), (x1, y1), (x2, y2) = points[i - 1], points[i], points[i + 1]
        d1, d2 = math.hypot(x1 - x0, y1 - y0), math.hypot(x2 - x1, y2 - y1)
        r = min(radius, d1 / 2, d2 / 2)
        ax, ay = x1 - (x1 - x0) / d1 * r, y1 - (y1 - y0) / d1 * r
        bx, by = x1 + (x2 - x1) / d2 * r, y1 + (y2 - y1) / d2 * r
        d += f" L{ax:.1f} {ay:.1f} Q{x1:g} {y1:g} {bx:.1f} {by:.1f}"
    d += f" L{points[-1][0]:g} {points[-1][1]:g}"
    return d


class Diagram:
    def __init__(self, name: str, width: float, height: float = 0):
        self.name, self.width, self.height = name, width, height
        self.parts = []
        self.warnings = []

    def check(self, text, size, room, mono=False, bold=False):
        needed = text_width(text, size, mono, bold)
        if needed > room:
            self.warnings.append(f'{self.name}: "{text}" needs about {needed:.0f} pt but has {room:.0f}')

    # MARK: Primitives

    def rect(self, x, y, w, h, tone="neutral", radius=10, dashed=False, fill="tone", stroke_width=1.25,
             shadow=False):
        """`fill` is "tone", "surface" (the page-like background), "stroke" (solid tone color) or "none"."""
        def draw(theme):
            tone_fill, stroke = TONES[theme][tone]
            color = {"tone": tone_fill, "surface": SURFACE[theme], "stroke": stroke, "none": "none"}[fill]
            dash = ' stroke-dasharray="5 4"' if dashed else ""
            outline = "none" if fill == "stroke" else stroke
            effect = ' filter="url(#shadow)"' if shadow else ""
            return (f'<rect x="{x:g}" y="{y:g}" width="{w:g}" height="{h:g}" rx="{radius:g}" fill="{color}" '
                    f'stroke="{outline}" stroke-width="{stroke_width:g}"{dash}{effect}/>')
        self.parts.append(draw)

    def text(self, x, y, value, size=13, color="text", mono=False, bold=False, anchor="middle", tone=None):
        """`color` is "text" or "secondary"; `tone` draws in that tone's stroke color instead."""
        def draw(theme):
            fill = TONES[theme][tone][1] if tone else INK[theme][color]
            weight = ' font-weight="600"' if bold else ""
            return (f'<text x="{x:g}" y="{y:g}" font-family="{MONO if mono else SANS}" font-size="{size:g}"'
                    f'{weight} fill="{fill}" text-anchor="{anchor}">{escape(value)}</text>')
        self.parts.append(draw)

    def line(self, points, color="line", dashed=False, width=1.25):
        d = rounded_path(points)
        def draw(theme):
            stroke = INK[theme]["line"] if color == "line" else TONES[theme][color][1]
            dash = ' stroke-dasharray="4 4"' if dashed else ""
            return f'<path d="{d}" fill="none" stroke="{stroke}" stroke-width="{width:g}"{dash}/>'
        self.parts.append(draw)

    def arrow(self, points, label=None, at=None, anchor="middle", color="line", dashed=False, head=True,
              tail=False, size=11, mono=True, width=1.5):
        """An arrow through `points`. The label goes at `at`, or just above the middle of the first segment."""
        d = rounded_path(points)
        def draw(theme):
            stroke = INK[theme]["line"] if color == "line" else TONES[theme][color][1]
            dash = ' stroke-dasharray="5 4"' if dashed else ""
            end = f' marker-end="url(#head-{color})"' if head else ""
            start = f' marker-start="url(#head-{color})"' if tail else ""
            return f'<path d="{d}" fill="none" stroke="{stroke}" stroke-width="{width:g}"{dash}{end}{start}/>'
        self.parts.append(draw)
        if label:
            if at is None:
                (x0, y0), (x1, y1) = points[0], points[1]
                at = ((x0 + x1) / 2, (y0 + y1) / 2 - 7)
            self.text(at[0], at[1], label, size, "secondary", mono, anchor=anchor)

    def box(self, x, y, w, h, title, lines=(), tone="neutral", mono=True, bold=False, title_size=13,
            line_size=11, align="center", valign="center", radius=10, dashed=False, fill="tone", pad=12,
            shadow=False):
        """A rounded box with a title and secondary lines. A line can be (text, is_mono)."""
        self.rect(x, y, w, h, tone, radius, dashed, fill, shadow=shadow)
        rows = [(title, title_size, mono, bold, "text")] if title else []
        for line in lines:
            value, is_mono = line if isinstance(line, tuple) else (line, False)
            rows.append((value, line_size, is_mono, False, "secondary"))
        gap = 5
        block = sum(row[1] for row in rows) + gap * (len(rows) - 1)
        top = y + (h - block) / 2 if valign == "center" else y + pad
        tx = x + w / 2 if align == "center" else x + pad
        anchor = "middle" if align == "center" else "start"
        for value, size, is_mono, is_bold, color in rows:
            top += size
            if value:
                self.check(value, size, w - 2 * pad, is_mono, is_bold)
                self.text(tx, round(top - size * 0.2, 1), value, size, color, is_mono, is_bold, anchor)
            top += gap

    def chip_width(self, label, size=11.5, mono=True):
        return text_width(label, size, mono) + 18

    def chips(self, x, y, width, labels, tone, size=11.5, mono=True, gap=8, draw=True):
        """Flows labels into rows of chips. Returns the height used."""
        cx, cy, row_h = x, y, size + 13
        for label in labels:
            w = self.chip_width(label, size, mono)
            if cx > x and cx + w > x + width:
                cx, cy = x, cy + row_h + gap
            if draw:
                self.rect(cx, cy, w, row_h, tone, radius=7, fill="surface", stroke_width=1)
                self.text(cx + w / 2, cy + row_h / 2 + size * 0.36, label, size, "text", mono)
            cx += w + gap
        return cy + row_h - y

    def diamond(self, cx, cy, w, h, lines, tone="neutral", size=12):
        points = f"{cx:g},{cy - h / 2:g} {cx + w / 2:g},{cy:g} {cx:g},{cy + h / 2:g} {cx - w / 2:g},{cy:g}"
        def draw(theme):
            fill, stroke = TONES[theme][tone]
            return f'<polygon points="{points}" fill="{fill}" stroke="{stroke}" stroke-width="1.25"/>'
        self.parts.append(draw)
        top = cy - (len(lines) * size + (len(lines) - 1) * 4) / 2
        for line in lines:
            top += size
            self.check(line, size, w * 0.55)
            self.text(cx, top - size * 0.2, line, size)
            top += 4

    def custom(self, draw):
        """Adds raw SVG produced by `draw(theme)`."""
        self.parts.append(draw)

    # MARK: Output

    def svg(self, theme) -> str:
        markers = {"line": INK[theme]["line"]}
        markers.update({tone: stroke for tone, (_, stroke) in TONES[theme].items()})
        defs = "".join(
            f'<marker id="head-{key}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="9" markerHeight="9" '
            f'markerUnits="userSpaceOnUse" orient="auto-start-reverse"><path d="M0 1 L9 5 L0 9 z" fill="{color}"/>'
            f'</marker>'
            for key, color in markers.items())
        defs += ('<filter id="shadow" x="-20%" y="-20%" width="140%" height="140%"><feDropShadow dx="0" dy="4" '
                 'stdDeviation="7" flood-color="#000" flood-opacity="0.22"/></filter>')
        body = "\n".join(part(theme) for part in self.parts)
        return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.width:g}" height="{self.height:g}" '
                f'viewBox="0 0 {self.width:g} {self.height:g}">\n<defs>{defs}</defs>\n{body}\n</svg>\n')


class Sequence:
    """Participants with lifelines, for sequence diagrams."""

    def __init__(self, d: Diagram, participants, top, bottom, size=11.5):
        self.d, self.x = d, {}
        self.top, self.bottom = top + size + 26, bottom
        # Labels that lifelines break around, as (left, right, top, bottom).
        self.labels = []
        for name, x, tone, mono in participants:
            self.x[name] = x
        # Drawn at render time, after every message has added its label.
        d.custom(self._lifelines)
        for name, x, tone, mono in participants:
            w = text_width(name, size, mono, bold=not mono) + 22
            d.box(x - w / 2, top, w, self.top - top, name, tone=tone, mono=mono, bold=not mono, title_size=size,
                  pad=8)

    def _lifelines(self, theme):
        out = []
        for x in self.x.values():
            gaps = sorted((t, b) for left, right, t, b in self.labels if left - 4 <= x <= right + 4)
            y = self.top
            for gap_top, gap_bottom in gaps + [(self.bottom, self.bottom)]:
                if gap_top > y:
                    out.append(f'<path d="M{x:g} {y:g} V{gap_top:g}" stroke="{INK[theme]["line"]}" '
                               f'stroke-width="1" stroke-dasharray="4 4"/>')
                y = max(y, gap_bottom)
        return "".join(out)

    def message(self, source, target, y, label, dashed=False, mono=True):
        x0, x1 = self.x[source], self.x[target]
        direction = 1 if x1 > x0 else -1
        self.d.arrow([(x0 + 2 * direction, y), (x1 - 2 * direction, y)], dashed=dashed)
        self.d.check(label, 11, abs(x1 - x0) - 10, mono)
        self.d.text((x0 + x1) / 2, y - 7, label, 11, "secondary", mono)
        half = text_width(label, 11, mono) / 2
        self.labels.append(((x0 + x1) / 2 - half, (x0 + x1) / 2 + half, y - 20, y - 3))

    def note(self, at, top, lines, width):
        """A note centered on a lifeline. Returns its bottom edge."""
        height = 14 + len(lines) * 15
        self.d.box(self.x[at] - width / 2, top, width, height, None, lines, "neutral", fill="surface",
                   line_size=11, radius=6, pad=8)
        return top + height


# MARK: - Diagrams


def architecture_layers():
    d = Diagram("architecture-layers", 900)
    tiers = [
        ("Views", ["SwiftUI screens and controls", "that read view models only"], "blue", True,
         ["PodcastsScreen", "EpisodesScreen", "FavoritesScreen", "RecentlyPlayedEpisodesScreen", "DownloadsScreen",
          "SettingsView", "PlayerDetailsView", "MiniPlayerView"]),
        ("View models", ["@MainActor observable objects", "that map models for display"], "blue", True,
         ["HomeViewModel", "PodcastDetailViewModel", "FavoritesViewModel", "HistoryViewModel", "SettingsViewModel",
          "PlayerViewModel", "DownloadsViewModel", "NewEpisodesViewModel"]),
        ("Managers", ["Business logic and", "app-wide state"], "purple", True,
         ["PodcastsManager", "EpisodesManager", "PlaybackManager", "DownloadManager", "NewEpisodesManager"]),
        ("Repositories", ["Return Podcast and Episode;", "hide Core Data and files"], "green", True,
         ["PodcastsRepository", "EpisodesRepository", "DownloadStore", "ListeningStats"]),
        ("Services", ["Network, database,", "defaults and caches"], "green", True,
         ["APIService", "CoreDataStack", "LegacyDatabaseImporter", "UserDefaults", "URLCache"]),
        ("Platform", ["Apple frameworks and", "remote data"], "gray", False,
         ["iTunes Search API", "RSS feeds", "Core Data", "AVFoundation", "MediaPlayer", "BackgroundTasks",
          "UserNotifications", "Network"]),
    ]
    x, w, label_w, gap = 20, 860, 210, 26
    chips_x, chips_w = x + label_w + 8, w - label_w - 8 - 16
    y = 20
    for index, (title, caption, tone, mono, labels) in enumerate(tiers):
        chips_h = d.chips(chips_x, 0, chips_w, labels, tone, mono=mono, draw=False)
        h = max(78, chips_h + 32)
        d.rect(x, y, w, h, tone)
        top = y + (h - 50) / 2
        d.check(title, 15, label_w - 26, bold=True)
        d.text(x + 18, top + 13, title, 15, bold=True, anchor="start")
        for i, line in enumerate(caption):
            d.check(line, 12, label_w - 26)
            d.text(x + 18, top + 33 + i * 16, line, 12, "secondary", anchor="start")
        d.chips(chips_x, y + (h - chips_h) / 2, chips_w, labels, tone, mono=mono)
        if index < len(tiers) - 1:
            d.arrow([(x + w / 2, y + h + 3), (x + w / 2, y + h + gap - 3)])
        y += h + gap
    d.height = y - gap + 20
    return d


def app_shell():
    d = Diagram("app-shell", 920, 556)
    d.text(165, 26, "Compact width (iPhone)", 13, "secondary", bold=True)
    d.text(615, 26, "Regular width (iPad)", 13, "secondary", bold=True)
    # iPhone
    d.rect(40, 40, 250, 470, "neutral", radius=36, stroke_width=2)
    d.box(56, 70, 218, 56, "NavigationStack", ["Title, search and toolbar"], "blue", title_size=12)
    d.box(56, 134, 218, 194, "Selected screen", ["Home, Favorites,", "Recently Played,", "Downloads or Settings"],
          "neutral", mono=False, bold=True, fill="surface")
    d.box(56, 336, 218, 52, "MiniPlayerView", ["Bottom safe-area inset"], "teal", title_size=12)
    d.box(56, 396, 218, 66, "TabView", ["One tab per section"], "purple", title_size=12)
    d.rect(120, 486, 90, 5, "gray", radius=2.5, fill="stroke")
    d.text(165, 538, "Expanded, the player covers the screen.", 12, "secondary")
    # iPad
    d.rect(330, 40, 570, 470, "neutral", radius=24, stroke_width=2)
    d.box(346, 56, 160, 438, "Sidebar", [("NavigationSplitView", True), "", "Home", "Favorites", "Recently Played",
                                         "Downloads", "Settings"],
          "purple", mono=False, bold=True, align="left", valign="top", line_size=11.5)
    d.box(516, 56, 368, 52, "NavigationStack", ["Title, search and toolbar"], "blue", title_size=12, align="left")
    d.box(516, 116, 368, 316, "Selected screen", ["The section chosen", "in the sidebar"], "neutral", mono=False,
          bold=True, fill="surface", align="left")
    d.box(516, 440, 368, 54, "MiniPlayerView", ["Bottom safe-area inset"], "teal", title_size=12, align="left")
    d.box(690, 56, 194, 438, "PlayerDetailsView", ["Expanded player,", "at most 440 pt wide"], "orange",
          title_size=12, shadow=True)
    d.text(615, 538, "Expanded, the player slides over the trailing edge.", 12, "secondary")
    return d


def state_propagation():
    d = Diagram("state-propagation", 920, 524)
    rows = [48, 148, 248, 348, 448]
    h = 52
    for x, title in ((155, "Write path"), (465, "Change events"), (780, "Republished state")):
        d.text(x, 26, title, 13, "secondary", bold=True)
    column = [("EpisodesScreen", [], "blue"), ("PodcastDetailViewModel", [], "blue"),
              ("PodcastsManager", [], "purple"), ("PodcastsRepository", [], "green"),
              ("CoreDataStack", ["Podcasts.sqlite"], "gray")]
    for (title, lines, tone), y in zip(column, rows):
        d.box(40, y, 230, h, title, lines, tone)
    for label, top in zip(["toggleFavorite()", "favorite(podcast:)", "favorite(podcast:)", "perform { … }"], rows):
        d.arrow([(155, top + h + 2), (155, top + 100 - 2)], label, at=(165, top + h + 28), anchor="start")
    d.box(350, rows[0], 230, h, "FavoritesScreen", [], "blue")
    d.box(350, rows[1], 230, h, "FavoritesViewModel", [], "blue")
    d.arrow([(272, rows[2] + h / 2), (465, rows[2] + h / 2), (465, rows[1] + h + 2)], "favoritesDidChange",
            at=(284, rows[2] + h / 2 - 8), anchor="start", color="purple")
    d.arrow([(465, rows[1] - 2), (465, rows[0] + h + 2)], "@Published favorites", at=(475, rows[1] - 20),
            anchor="start")
    d.box(660, rows[0], 240, h, "PlayerDetailsView", ["MiniPlayerView and rows"], "blue")
    d.box(660, rows[1], 240, h, "PlayerViewModel", [], "blue")
    d.box(660, rows[2], 240, h, "PlaybackManager", ["@Published state"], "purple")
    d.arrow([(780, rows[2] - 2), (780, rows[1] + h + 2)], "objectWillChange", at=(790, rows[2] - 20),
            anchor="start", color="purple")
    d.arrow([(780, rows[1] - 2), (780, rows[0] + h + 2)], "objectWillChange", at=(790, rows[1] - 20),
            anchor="start")
    return d


def search_sequence():
    d = Diagram("search-sequence", 960, 624)
    seq = Sequence(d, [("PodcastsScreen", 80, "blue", True), ("HomeViewModel", 240, "blue", True),
                       ("PodcastsManager", 400, "purple", True), ("PodcastsRepository", 560, "green", True),
                       ("APIService", 720, "green", True), ("iTunes Search API", 875, "orange", False)],
                   top=20, bottom=604)
    seq.message("PodcastsScreen", "HomeViewModel", 100, "searchText")
    seq.note("HomeViewModel", 122, ["Waits 333 ms and", "needs 3+ characters"], 150)
    seq.message("HomeViewModel", "PodcastsManager", 196, "searchPodcasts")
    seq.message("PodcastsManager", "PodcastsRepository", 238, "search(forValue:)")
    seq.message("PodcastsRepository", "APIService", 280, "fetchPodcastsAsync")
    seq.message("APIService", "iTunes Search API", 322, "GET /search")
    seq.message("iTunes Search API", "APIService", 364, "JSON results", dashed=True, mono=False)
    seq.note("APIService", 384, ["Skips results", "without a feedUrl"], 140)
    seq.message("APIService", "PodcastsRepository", 458, "[Podcast]", dashed=True)
    seq.message("PodcastsRepository", "PodcastsManager", 500, "[Podcast]", dashed=True)
    seq.message("PodcastsManager", "HomeViewModel", 542, "[Podcast]", dashed=True)
    seq.message("HomeViewModel", "PodcastsScreen", 584, "@Published podcasts", dashed=True)
    return d


def playback_sequence():
    d = Diagram("playback-sequence", 960, 624)
    seq = Sequence(d, [("EpisodesScreen", 70, "blue", True), ("AppTabView", 205, "blue", True),
                       ("PlayerViewModel", 340, "blue", True), ("PlaybackManager", 475, "purple", True),
                       ("DownloadStore", 610, "green", True), ("AVPlayer", 745, "gray", True),
                       ("EpisodesManager", 880, "purple", True)],
                   top=20, bottom=604, size=11)
    seq.message("EpisodesScreen", "AppTabView", 100, "maximizePlayerView")
    seq.message("AppTabView", "PlayerViewModel", 142, "play(_:queue:)")
    seq.note("AppTabView", 162, ["Expands", "the player"], 116)
    seq.note("PlayerViewModel", 162, ["Already loaded?", "Resumes instead"], 124)
    seq.message("PlayerViewModel", "PlaybackManager", 236, "load(_:queue:)")
    seq.message("PlaybackManager", "DownloadStore", 278, "existingFile(for:)")
    seq.message("DownloadStore", "PlaybackManager", 320, "file URL or nil", dashed=True, mono=False)
    seq.message("PlaybackManager", "AVPlayer", 362, "replaceCurrentItem")
    seq.note("PlaybackManager", 382, ["Seeks to the saved", "position when ready"], 150)
    seq.message("PlaybackManager", "EpisodesManager", 456, "saveInHistory(episode:)")
    seq.note("EpisodesManager", 476, ["Sends", "historyDidChange"], 128)
    seq.message("AVPlayer", "PlaybackManager", 550, "time, every second", dashed=True, mono=False)
    seq.message("PlaybackManager", "PlayerViewModel", 588, "objectWillChange", dashed=True)
    return d


def playback_system():
    d = Diagram("playback-system", 920, 446)
    d.box(335, 20, 250, 54, "PlayerViewModel", ["Read by the player, mini player and rows"], "blue")
    d.box(320, 124, 280, 176, "PlaybackManager.shared",
          ["One AVPlayer for the whole app", "Queue and Up Next", "Resume positions and durations",
           "Speed: 1×, 1.25×, 1.5× or 2×", "Listening time"], "purple", line_size=12)
    d.arrow([(460, 122), (460, 76)], "@Published", at=(468, 103), anchor="start", color="purple")
    d.box(20, 124, 250, 76, "MPRemoteCommandCenter", ["Play, pause, ±15 s, next,", "previous and scrubbing"], "gray")
    d.box(20, 224, 250, 76, "AVAudioSession", ["Pauses for interruptions", "and unplugged headphones"], "gray")
    d.arrow([(272, 162), (318, 162)])
    d.arrow([(272, 262), (318, 262)])
    d.box(650, 124, 250, 76, "AVPlayer", ["Streams the episode or", "plays the downloaded file"], "gray")
    d.box(650, 224, 250, 76, "MPNowPlayingSession", ["Title, show and artwork on the", "Lock Screen"], "gray")
    d.arrow([(602, 162), (648, 162)])
    d.arrow([(602, 262), (648, 262)])
    d.box(20, 350, 270, 76, "UserDefaults", ["Positions by streamUrl, durations,", "speed and listening time"], "green")
    d.box(325, 350, 270, 76, "DownloadStore", ["The downloaded copy of the", "episode, if there is one"], "green")
    d.box(630, 350, 270, 76, "EpisodesManaging", [("saveInHistory(episode:)", True), "records each play"],
          "purple")
    d.arrow([(400, 302), (400, 325), (155, 325), (155, 348)])
    d.arrow([(460, 302), (460, 348)])
    d.arrow([(520, 302), (520, 325), (765, 325), (765, 348)])
    return d


def download_lifecycle():
    d = Diagram("download-lifecycle", 920, 440)
    d.box(30, 150, 200, 60, "Not downloaded", [], "gray", mono=False, bold=True)
    d.box(360, 150, 200, 60, "Downloading", ["Progress from 0 to 100%"], "blue", mono=False, bold=True)
    d.box(690, 150, 200, 60, "Downloaded", ["Audio file and sidecar"], "green", mono=False, bold=True)
    d.box(360, 320, 200, 60, "Failed", ["Shows the error"], "red", mono=False, bold=True)
    d.arrow([(232, 168), (358, 168)], "download()", at=(295, 160))
    d.arrow([(358, 194), (232, 194)], "cancel()", at=(295, 212))
    d.arrow([(562, 180), (688, 180)], "finished", at=(625, 172), mono=False)
    d.arrow([(790, 148), (790, 90), (130, 90), (130, 148)], "remove()", at=(460, 82))
    d.arrow([(430, 212), (430, 318)], "error", at=(422, 270), anchor="end", mono=False)
    d.arrow([(490, 318), (490, 212)], "retry", at=(498, 270), anchor="start", mono=False)
    d.box(30, 300, 280, 100, "Background session", ["Keeps downloading while the", "app is suspended or not running"],
          "neutral", mono=False, bold=True, fill="surface", dashed=True)
    d.box(610, 300, 280, 100, "Download on Wi-Fi Only", ["Holds new downloads until", "Wi-Fi is available"],
          "neutral", mono=False, bold=True, fill="surface", dashed=True)
    return d


def download_files():
    d = Diagram("download-files", 920, 236)
    d.box(20, 90, 170, 56, "streamUrl", ["The episode’s identity"], "blue")
    d.box(225, 90, 140, 56, "SHA-256", ["Hex digest"], "neutral", mono=False, bold=True)
    d.box(400, 90, 155, 56, "<stem>", ["64 hex characters"], "neutral")
    d.arrow([(192, 118), (223, 118)])
    d.arrow([(367, 118), (398, 118)])
    d.rect(590, 20, 310, 196, "gray", dashed=True)
    d.text(606, 44, "Application Support/Downloads", 12, mono=True, anchor="start")
    d.text(606, 62, "Excluded from iCloud backup", 11, "secondary", anchor="start")
    d.box(610, 78, 270, 56, "<stem>.mp3", ["Audio; extension from the URL or type"], "green", align="left")
    d.box(610, 146, 270, 56, "<stem>.json", ["The Episode, saved when it starts"], "green", align="left")
    d.arrow([(557, 118), (582, 118), (582, 106), (608, 106)])
    d.arrow([(557, 118), (582, 118), (582, 174), (608, 174)])
    return d


def new_episode_detection():
    d = Diagram("new-episode-detection", 920, 556)
    d.box(20, 20, 250, 220, "Checks run on", ["Launch and return to foreground,", "skipped within 15 minutes",
                                                 "", "Pull to refresh on Home", "and Favorites", "",
                                                 "Check Now in Settings", "", "Background app refresh,",
                                                 "when iOS allows"],
          "gray", mono=False, bold=True, align="left", valign="top", line_size=11.5)
    d.arrow([(272, 45), (328, 45)])
    d.box(330, 20, 260, 50, "Load presets", [("fetchFavorites()", True)], "purple", mono=False, bold=True)
    d.box(330, 100, 260, 50, "Fetch every feed at once", ["A failed feed keeps its results"], "purple",
          mono=False, bold=True)
    d.arrow([(460, 72), (460, 98)])
    d.arrow([(460, 152), (460, 158)])
    d.diamond(460, 205, 240, 94, ["First check of", "this preset?"], "orange")
    d.arrow([(580, 205), (648, 205)], "Yes", at=(614, 197), mono=False)
    d.box(650, 177, 250, 56, "Remember the feed", ["Every current episode counts as old"], "gray", mono=False,
          bold=True)
    d.arrow([(460, 252), (460, 278)], "No", at=(468, 270), anchor="start", mono=False)
    d.box(330, 280, 260, 96, "Keep episodes that are", ["not in the feed at the last visit,",
                                                         "not played from the shelf, and",
                                                         "dated after the last visit"],
          "purple", mono=False, bold=True)
    d.arrow([(460, 378), (460, 404)])
    d.box(330, 406, 260, 50, "Keep the newest 10 per podcast", ["Fresh on Air shelf and NEW badges"], "purple",
          mono=False, bold=True)
    d.arrow([(460, 458), (460, 484)])
    d.box(330, 486, 260, 50, "Save NewEpisodes.json", ["Then notify once per episode"], "purple", mono=False,
          bold=True)
    d.box(650, 380, 250, 102, "Clearing", ["Opening a podcast clears its new", "episodes (markSeen). Playing one",
                                            "from the shelf removes it", "(markPlayed)."],
          "teal", mono=False, bold=True, align="left")
    d.arrow([(648, 431), (592, 431)], dashed=True, color="teal")
    return d


def storage_map():
    d = Diagram("storage-map", 940, 440)
    columns = [
        (20, "Application Support", "Files and databases", "green", [
            ("Podcasts.sqlite", ["Favorites and history (Core Data)"], False),
            ("Downloads/", ["Episode audio and JSON sidecars"], False),
            ("NewEpisodes.json", ["New-episode tracking state"], False),
            ("db.sqlite", ["The old GRDB database, imported", "once and then deleted"], True),
        ]),
        (330, "UserDefaults", "Small values", "purple", [
            ("<streamUrl>", ["Resume position, in seconds"], False),
            ("duration:<streamUrl>", ["Episode length, for progress"], False),
            ("playbackRate", ["Chosen playback speed"], False),
            ("listeningSecondsByDay", ["Listening time per day"], False),
            ("downloadsWiFiOnly", ["Download on Wi-Fi Only"], False),
            ("newEpisodeNotificationsEnabled", ["New Episode Alerts"], False),
        ]),
        (640, "URLCache.shared", "Artwork and other responses", "blue", [
            ("Memory", ["Up to 50 MB"], False),
            ("Disk", ["Up to 200 MB; Clear Cache", "in Settings empties it"], False),
        ]),
    ]
    width = 280
    for x, title, caption, tone, rows in columns:
        y = 80
        heights = [20 + 13 + len(desc) * 15 for _, desc, _ in rows]
        total = 60 + sum(heights) + 8 * (len(rows) - 1) + 14
        d.rect(x, 20, width, total, tone)
        d.text(x + 16, 44, title, 14, bold=True, mono=title.endswith("shared"), anchor="start")
        d.text(x + 16, 62, caption, 11.5, "secondary", anchor="start")
        for (key, desc, dashed), h in zip(rows, heights):
            d.box(x + 12, y, width - 24, h, key, desc, tone, title_size=12, align="left", fill="surface",
                  radius=7, dashed=dashed)
            y += h + 8
    return d


def core_data_model():
    d = Diagram("core-data-model", 920, 470)

    def entity(x, name, rows):
        w, row_h, header = 380, 26, 40
        h = header + len(rows) * row_h + 8
        d.rect(x, 20, w, h, "green")
        d.custom(lambda theme, x=x: f'<path d="M{x} {20 + header} H{x + w}" stroke="{TONES[theme]["green"][1]}" '
                                    f'stroke-width="1"/>')
        d.text(x + 16, 20 + 26, name, 14, mono=True, bold=True, anchor="start")
        for i, (attribute, kind, note) in enumerate(rows):
            y = 20 + header + i * row_h + 18
            d.text(x + 16, y, attribute, 12, mono=True, anchor="start", bold=bool(note == "unique"))
            d.text(x + 180, y, kind, 12, "secondary", mono=True, anchor="start")
            if note:
                d.text(x + w - 16, y, note, 11, anchor="end", tone="green" if note == "unique" else None,
                       color="secondary")
        return 20 + h

    favorite_bottom = entity(20, "FavoritePodcastEntity", [
        ("rssFeedUrl", "String", "unique"), ("favoritedAt", "Date", "preset order"), ("recordId", "String?", ""),
        ("title", "String?", ""), ("author", "String?", ""), ("image", "String?", ""),
        ("totalEpisodes", "Int64?", "")])
    history_bottom = entity(520, "HistoryEpisodeEntity", [
        ("streamUrl", "String", "unique"), ("lastPlayedAt", "Date", "newest first"), ("title", "String", ""),
        ("subtitle", "String", ""), ("pubDate", "Date", ""), ("episodeDescription", "String", ""),
        ("author", "String", ""), ("fileUrl", "String?", ""), ("imageUrl", "String?", ""),
        ("podcastFeedUrl", "String?", "")])
    rss_y, feed_y = 20 + 40 + 13, 20 + 40 + 9 * 26 + 13
    d.line([(400, rss_y), (460, rss_y), (460, feed_y), (520, feed_y)], dashed=True)
    d.text(468, (rss_y + feed_y) / 2 - 6, "ON AIR", 11, "secondary", anchor="start")
    d.text(468, (rss_y + feed_y) / 2 + 8, "match", 11, "secondary", anchor="start")
    d.box(110, 390, 200, 56, "Podcast", ["Domain model"], "purple")
    d.box(610, 390, 200, 56, "Episode", ["Domain model"], "purple")
    d.arrow([(210, favorite_bottom + 2), (210, 388)], "update(from:) / .podcast", at=(220, 330), anchor="start",
            head=True, tail=True)
    d.arrow([(710, history_bottom + 2), (710, 388)], "update(from:) / .episode", at=(720, 362), anchor="start",
            head=True, tail=True)
    return d


def networking():
    d = Diagram("networking", 940, 300)
    d.text(20, 40, "Searching", 13, "secondary", bold=True, anchor="start")
    d.box(20, 52, 240, 64, "APIService", [("fetchPodcastsAsync(searchText:)", True)], "green")
    d.box(290, 52, 250, 64, "iTunes Search API", ["GET itunes.apple.com/search", "media and entity podcast, limit 50"],
          "orange", mono=False, bold=True)
    d.box(570, 52, 220, 64, "Decode", ["Skip results without a feedUrl", "and repeated feeds"], "neutral",
          mono=False, bold=True)
    d.box(820, 52, 110, 64, "[Podcast]", ["by rssFeedUrl"], "purple")
    d.text(20, 160, "Loading episodes", 13, "secondary", bold=True, anchor="start")
    d.box(20, 172, 240, 64, "APIService", [("fetchEpisodesAsync(forPodcast:)", True)], "green")
    d.box(290, 172, 250, 64, "Podcast RSS feed", ["GET the podcast’s rssFeedUrl,", "over HTTP or HTTPS"], "orange",
          mono=False, bold=True)
    d.box(570, 172, 220, 64, "FeedKit", [("FeedParser", True), ("RSSFeed.toEpisodes()", True)], "neutral",
          mono=False, bold=True)
    d.box(820, 172, 110, 64, "[Episode]", ["by streamUrl"], "purple")
    for y in (84, 204):
        d.arrow([(262, y), (288, y)])
        d.arrow([(542, y), (568, y)])
        d.arrow([(792, y), (818, y)])
    d.text(470, 280, "Requests time out after 30 seconds, and 60 for the whole resource. Failures surface as APIError.",
           11.5, "secondary")
    return d


def dependency_injection():
    d = Diagram("dependency-injection", 940, 470)
    d.rect(20, 20, 600, 300, "gray", dashed=True)
    d.text(36, 46, "Resolver: registerAllServices()", 12.5, mono=True, anchor="start")
    for x, label in ((40, "Services"), (250, "Repositories"), (450, "Managers")):
        d.text(x, 78, label, 11.5, "secondary", bold=True, anchor="start")
    d.box(40, 96, 180, 52, "APIService.shared", [], "green", title_size=12)
    d.box(40, 196, 180, 52, "CoreDataStack.shared", [], "green", title_size=12)
    d.box(250, 94, 170, 56, "PodcastsRepository", ["Application scope"], "green", title_size=12)
    d.box(250, 194, 170, 56, "EpisodesRepository", ["Application scope"], "green", title_size=12)
    d.box(450, 94, 150, 56, "PodcastsManager", [("as PodcastsManaging", True)], "purple", title_size=12,
          line_size=10.5)
    d.box(450, 194, 150, 56, "EpisodesManager", [("as EpisodesManaging", True)], "purple", title_size=12,
          line_size=10.5)
    d.line([(222, 122), (235, 122)])
    d.line([(222, 222), (235, 222)])
    d.line([(235, 122), (235, 222)])
    d.arrow([(235, 122), (248, 122)])
    d.arrow([(235, 222), (248, 222)])
    d.arrow([(422, 122), (448, 122)])
    d.arrow([(422, 222), (448, 222)])
    d.text(36, 300, "Repositories and managers are registered by protocol, so tests can swap them.", 11.5,
           "secondary", anchor="start")
    d.rect(650, 20, 270, 300, "purple", dashed=True)
    d.text(666, 46, "Main-actor singletons", 13, bold=True, anchor="start")
    for i, name in enumerate(["PlaybackManager.shared", "DownloadManager.shared", "NewEpisodesManager.shared"]):
        d.box(670, 72 + i * 66, 230, 50, name, [], "purple", title_size=12, fill="surface")
    d.text(666, 300, "Created on first use", 11.5, "secondary", anchor="start")
    d.box(20, 370, 900, 80, "ViewModels", ["Resolve data managers as initializer defaults, and take singletons as "
                                           "optionals that default to .shared.",
                                           "Tests pass mocks to the same initializers."], "blue", line_size=12)
    d.arrow([(525, 322), (525, 368)], "Resolver.resolve()", at=(535, 350), anchor="start")
    d.arrow([(785, 322), (785, 368)], "nil → .shared", at=(795, 350), anchor="start")
    return d


def listening_heatmap():
    d = Diagram("listening-heatmap", 720, 190)
    cell, gap, weeks = 13, 3, 26
    seed = 7
    levels = []
    for _ in range(weeks * 7):
        seed = (seed * 1103515245 + 12345) % 2**31
        roll = seed % 100
        levels.append(0 if roll < 38 else 1 if roll < 62 else 2 if roll < 80 else 3 if roll < 93 else 4)
    origin_x, origin_y = 20, 34
    d.text(origin_x, 22, "One column per week, one row per weekday", 11.5, "secondary", anchor="start")

    def grid(theme):
        out = []
        for week in range(weeks):
            # Today is a Thursday, so the rest of this week is still empty.
            for day in range(7 if week < weeks - 1 else 5):
                level = levels[week * 7 + day]
                x, y = origin_x + week * (cell + gap), origin_y + day * (cell + gap)
                out.append(f'<rect x="{x}" y="{y}" width="{cell}" height="{cell}" rx="3" fill="{HEAT[theme][level]}"/>')
        return "".join(out)
    d.custom(grid)
    legend = ["No listening", "1 to 14 minutes", "15 to 29 minutes", "30 to 59 minutes", "An hour or more"]
    for level, label in enumerate(legend):
        y = 34 + level * 26
        d.custom(lambda theme, y=y, level=level: f'<rect x="470" y="{y}" width="16" height="16" rx="3" '
                                                 f'fill="{HEAT[theme][level]}"/>')
        d.text(496, y + 12.5, label, 12, anchor="start")
    d.text(origin_x, 176, "Today is the last filled square; days after it in this week stay empty.", 11.5,
           "secondary", anchor="start")
    return d


DIAGRAMS = [architecture_layers, app_shell, state_propagation, search_sequence, playback_sequence,
            playback_system, download_lifecycle, download_files, new_episode_detection, storage_map,
            core_data_model, networking, dependency_injection, listening_heatmap]


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    warnings = []
    for make in DIAGRAMS:
        diagram = make()
        for theme in THEMES:
            suffix = "" if theme == "light" else "~dark"
            (OUTPUT / f"{diagram.name}{suffix}.svg").write_text(diagram.svg(theme), encoding="utf-8")
        warnings += diagram.warnings
        print(f"{diagram.name}: {diagram.width:g} × {diagram.height:g}")
    for warning in warnings:
        print(f"warning: {warning}", file=sys.stderr)


if __name__ == "__main__":
    main()
