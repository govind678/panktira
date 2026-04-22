# Panktira

A lightweight, native macOS CSV editor built with SwiftUI.

## Features

- **Spreadsheet-style editing** — click to select, double-click or press Return to edit cells inline
- **Tabs** — open multiple CSV files in a single window (Cmd+T for new tab)
- **Find & Replace** — search across all cells with options for match mode (contains, whole word, entire cell, starts with, ends with), case sensitivity, and wrap-around
- **Row & column operations** — insert, delete, move, and reorder rows and columns via the Table menu
- **Undo / Redo** — full snapshot-based undo history
- **Zoom** — scale the spreadsheet from 50% to 200% (Cmd+/Cmd-)
- **Resizable columns** — drag column borders to resize; double-click to auto-fit
- **Drag & drop** — drop a `.csv` file onto the window to open it
- **Recent documents** — File > Open Recent menu integration
- **RFC 4180 CSV parsing** — handles quoted fields, embedded commas, embedded newlines, and escaped quotes

## Requirements

- macOS 14+ (Sonoma)
- Xcode 16+

## Building

Open `Panktira.xcodeproj` in Xcode and build (Cmd+B).
