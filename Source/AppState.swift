//
//  AppState.swift
//  Panktira
//

import SwiftUI
import AppKit

// MARK: - TabState

/// Holds all state that is unique to a single tab: its document, selection,
/// editing state, find/replace, zoom, and column widths.
@Observable
final class TabState: Identifiable {
    let id = UUID()

    // MARK: - Document

    var document = CSVDocument()

    // MARK: - Zoom

    var zoomLevel: CGFloat = 1.0

    private static let zoomStep: CGFloat = 0.1
    private static let minZoom: CGFloat = 0.5
    private static let maxZoom: CGFloat = 2.0

    var zoomPercentageText: String {
        "\(Int(round(zoomLevel * 100)))%"
    }

    var canZoomIn: Bool { zoomLevel < Self.maxZoom - 0.001 }
    var canZoomOut: Bool { zoomLevel > Self.minZoom + 0.001 }

    func zoomIn() {
        zoomLevel = min(Self.maxZoom, ((zoomLevel + Self.zoomStep) * 10).rounded() / 10)
    }

    func zoomOut() {
        zoomLevel = max(Self.minZoom, ((zoomLevel - Self.zoomStep) * 10).rounded() / 10)
    }

    func resetZoom() {
        zoomLevel = 1.0
    }

    // MARK: - Scaled Dimensions

    static let baseCellHeight: CGFloat = 30
    static let baseRowNumberWidth: CGFloat = 50
    static let baseBodyFontSize: CGFloat = 12
    static let baseCaptionFontSize: CGFloat = 10

    var scaledCellHeight: CGFloat { Self.baseCellHeight * zoomLevel }
    var scaledRowNumberWidth: CGFloat { Self.baseRowNumberWidth * zoomLevel }
    var scaledBodyFontSize: CGFloat { Self.baseBodyFontSize * zoomLevel }
    var scaledCaptionFontSize: CGFloat { Self.baseCaptionFontSize * zoomLevel }
    var scaledMinimumColumnWidth: CGFloat { Self.minimumColumnWidth * zoomLevel }
    var scaledDefaultColumnWidth: CGFloat { Self.defaultColumnWidth * zoomLevel }

    // MARK: - Column Widths

    static let defaultColumnWidth: CGFloat = 120
    static let minimumColumnWidth: CGFloat = 40

    var columnWidths: [CGFloat] = []

    func widthForColumn(_ index: Int) -> CGFloat {
        guard index >= 0, index < columnWidths.count else { return Self.defaultColumnWidth }
        return columnWidths[index]
    }

    /// Ensure columnWidths array matches the document's column count.
    func syncColumnWidths() {
        let count = document.columnCount
        while columnWidths.count < count {
            columnWidths.append(Self.defaultColumnWidth)
        }
        if columnWidths.count > count {
            columnWidths = Array(columnWidths.prefix(count))
        }
    }

    /// Reset all column widths to default for the current document.
    func resetColumnWidths() {
        columnWidths = Array(repeating: Self.defaultColumnWidth, count: document.columnCount)
    }

    // MARK: - Selection

    var selectedRow: Int? = nil
    var selectedColumn: Int? = nil

    /// Display label for the currently selected cell, e.g. "A1" or "B" (header).
    var selectedCellAddress: String? {
        guard let col = selectedColumn else { return nil }
        let letter = CSVDocument.columnLetter(for: col)
        guard let row = selectedRow else { return nil }
        if row == -1 { return letter }
        return "\(letter)\(row + 1)"
    }

    /// The current text value of the selected cell (read-only).
    var selectedCellValue: String {
        guard let col = selectedColumn else { return "" }
        guard let row = selectedRow else { return "" }
        if row == -1 {
            return document.headerValue(column: col)
        }
        return document.cellValue(row: row, column: col)
    }

    // MARK: - Editing

    var isEditing: Bool = false
    var editText: String = ""

    func beginEditing() {
        guard selectedRow != nil, selectedColumn != nil else { return }
        editText = selectedCellValue
        isEditing = true
    }

    func commitEdit() {
        guard isEditing else { return }
        guard let col = selectedColumn, let row = selectedRow else {
            isEditing = false
            return
        }
        if row == -1 {
            document.updateHeader(column: col, value: editText)
        } else {
            document.updateCell(row: row, column: col, value: editText)
        }
        isEditing = false
    }

    func cancelEdit() {
        isEditing = false
        editText = ""
    }

    // MARK: - Arrow Key Navigation

    func moveSelectionUp() {
        guard let row = selectedRow else { return }
        if row == -1 { return }
        if selectedColumn == nil { selectedColumn = 0 }
        if row == 0 {
            selectedRow = -1
        } else {
            selectedRow = row - 1
        }
    }

    func moveSelectionDown() {
        guard let row = selectedRow else {
            selectedRow = 0
            if selectedColumn == nil { selectedColumn = 0 }
            return
        }
        if selectedColumn == nil { selectedColumn = 0 }
        if row == -1 {
            selectedRow = 0
        } else if row < document.rowCount - 1 {
            selectedRow = row + 1
        }
    }

    func moveSelectionLeft() {
        guard let col = selectedColumn else { return }
        if col > 0 {
            selectedColumn = col - 1
        }
    }

    func moveSelectionRight() {
        guard let col = selectedColumn else { return }
        if col < document.columnCount - 1 {
            selectedColumn = col + 1
        }
    }

    // MARK: - Find & Replace

    var showFindPanel = false
    var searchText = ""
    var replaceText = ""
    var searchOptions = SearchOptions()
    var searchResults: [CSVDocument.CellAddress] = []
    var currentSearchIndex = 0

    var highlightedCells: Set<CellPosition> {
        Set(searchResults.map { CellPosition(row: $0.row, column: $0.column) })
    }

    var highlightedRows: Set<Int> {
        Set(searchResults.map(\.row))
    }

    var focusedSearchCell: CellPosition? {
        guard !searchResults.isEmpty,
              currentSearchIndex >= 0,
              currentSearchIndex < searchResults.count else { return nil }
        let addr = searchResults[currentSearchIndex]
        return CellPosition(row: addr.row, column: addr.column)
    }

    func showFind() {
        showFindPanel = true
    }

    func dismissFind() {
        showFindPanel = false
        searchText = ""
        replaceText = ""
        searchResults = []
        currentSearchIndex = 0
    }

    func toggleFind() {
        if showFindPanel {
            dismissFind()
        } else {
            showFindPanel = true
        }
    }

    func performSearch() {
        searchResults = document.findCells(matching: searchText, options: searchOptions)
        if searchResults.isEmpty {
            currentSearchIndex = 0
        } else if currentSearchIndex >= searchResults.count {
            currentSearchIndex = 0
        }
    }

    func findNext() {
        guard !searchResults.isEmpty else { return }
        if currentSearchIndex + 1 < searchResults.count {
            currentSearchIndex += 1
        } else if searchOptions.wrapAround {
            currentSearchIndex = 0
        }
        selectFocusedCell()
    }

    func findPrevious() {
        guard !searchResults.isEmpty else { return }
        if currentSearchIndex - 1 >= 0 {
            currentSearchIndex -= 1
        } else if searchOptions.wrapAround {
            currentSearchIndex = searchResults.count - 1
        }
        selectFocusedCell()
    }

    private func selectFocusedCell() {
        guard let cell = focusedSearchCell else { return }
        selectedRow = cell.row
        selectedColumn = cell.column
    }

    // MARK: - Replace Actions

    func replaceCurrent() {
        guard !searchResults.isEmpty,
              currentSearchIndex >= 0,
              currentSearchIndex < searchResults.count else { return }

        let address = searchResults[currentSearchIndex]
        let didReplace = document.replaceCell(
            at: address,
            query: searchText,
            replacement: replaceText,
            options: searchOptions
        )

        if didReplace {
            performSearch()
            if currentSearchIndex >= searchResults.count && !searchResults.isEmpty {
                currentSearchIndex = searchOptions.wrapAround ? 0 : searchResults.count - 1
            }
            selectFocusedCell()
        }
    }

    func replaceAll() {
        let count = document.replaceAll(
            query: searchText,
            replacement: replaceText,
            options: searchOptions
        )
        if count > 0 {
            performSearch()
        }
    }

    // MARK: - Row Operations

    func insertRowAbove() {
        let index = selectedRow ?? 0
        if index >= 0 {
            document.insertRowAbove(index)
        }
    }

    func insertRowBelow() {
        let index = selectedRow ?? (document.rowCount - 1)
        if index >= 0 {
            document.insertRowBelow(index)
        }
    }

    func deleteSelectedRow() {
        guard let row = selectedRow, row >= 0 else { return }
        document.deleteRow(row)
        if row >= document.rowCount {
            selectedRow = document.rowCount - 1
        }
    }

    // MARK: - Column Operations

    func insertColumnBefore() {
        let index = selectedColumn ?? 0
        let safeIndex = max(0, min(index, columnWidths.count))
        columnWidths.insert(Self.defaultColumnWidth, at: safeIndex)
        document.insertColumnBefore(index)
    }

    func insertColumnAfter() {
        let index = selectedColumn ?? (document.columnCount - 1)
        let safeIndex = max(0, min(index + 1, columnWidths.count))
        columnWidths.insert(Self.defaultColumnWidth, at: safeIndex)
        document.insertColumnAfter(index)
    }

    func deleteSelectedColumn() {
        guard let col = selectedColumn else { return }
        if col >= 0, col < columnWidths.count {
            columnWidths.remove(at: col)
        }
        document.deleteColumn(col)
        if col >= document.columnCount {
            selectedColumn = document.columnCount - 1
        }
    }

    // MARK: - Move Operations

    func moveRowUp() {
        guard let row = selectedRow, row >= 0 else { return }
        document.moveRowUp(row)
        if row > 0 { selectedRow = row - 1 }
    }

    func moveRowDown() {
        guard let row = selectedRow, row >= 0 else { return }
        document.moveRowDown(row)
        if row < document.rowCount - 1 { selectedRow = row + 1 }
    }

    func moveColumnLeft() {
        guard let col = selectedColumn else { return }
        if col > 0, col < columnWidths.count {
            columnWidths.swapAt(col, col - 1)
        }
        document.moveColumnLeft(col)
        if col > 0 { selectedColumn = col - 1 }
    }

    func moveColumnRight() {
        guard let col = selectedColumn else { return }
        if col >= 0, col < columnWidths.count - 1 {
            columnWidths.swapAt(col, col + 1)
        }
        document.moveColumnRight(col)
        if col < document.columnCount - 1 { selectedColumn = col + 1 }
    }

    // MARK: - Tab Display Name

    var tabDisplayName: String {
        if let url = document.fileURL {
            return url.deletingPathExtension().lastPathComponent
        }
        return "Untitled"
    }

    // MARK: - Init

    init() {
        syncColumnWidths()
    }
}

// MARK: - AppState

/// Top-level app state managing a collection of tabs.
@Observable
final class AppState {
    // MARK: - Tabs

    var tabs: [TabState] = []
    var activeTabIndex: Int = 0

    /// The currently active tab. Always valid as long as tabs is non-empty.
    var activeTab: TabState {
        guard activeTabIndex >= 0, activeTabIndex < tabs.count else {
            return tabs[0]
        }
        return tabs[activeTabIndex]
    }

    init() {
        let initialTab = TabState()
        tabs = [initialTab]
        activeTabIndex = 0
    }

    // MARK: - Tab Management

    /// Create a new tab with a blank document and switch to it.
    func newTab() {
        let tab = TabState()
        tabs.append(tab)
        activeTabIndex = tabs.count - 1
    }

    /// Close the tab at the given index. If it's the last tab, create a fresh one.
    func closeTab(at index: Int) {
        guard index >= 0, index < tabs.count else { return }

        let tab = tabs[index]
        if tab.document.isModified {
            let alert = NSAlert()
            alert.messageText = "Do you want to save changes to \"\(tab.tabDisplayName)\"?"
            alert.informativeText = "Your changes will be lost if you don't save them."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Don't Save")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            switch response {
            case .alertFirstButtonReturn:
                tab.document.save()
            case .alertSecondButtonReturn:
                break // Don't save — proceed
            default:
                return // Cancel — abort close
            }
        }

        tabs.remove(at: index)

        if tabs.isEmpty {
            // Always keep at least one tab
            let freshTab = TabState()
            tabs.append(freshTab)
            activeTabIndex = 0
        } else if activeTabIndex >= tabs.count {
            activeTabIndex = tabs.count - 1
        } else if activeTabIndex > index {
            activeTabIndex -= 1
        }
        // If activeTabIndex == index and index is still valid, we stay on same index
        // (which is now the next tab). This is standard tab-close behavior.
    }

    /// Close the currently active tab.
    func closeActiveTab() {
        closeTab(at: activeTabIndex)
    }

    /// Switch to the previous tab (wraps around).
    func selectPreviousTab() {
        guard tabs.count > 1 else { return }
        let newIndex = activeTabIndex > 0 ? activeTabIndex - 1 : tabs.count - 1
        switchToTab(at: newIndex)
    }

    /// Switch to the next tab (wraps around).
    func selectNextTab() {
        guard tabs.count > 1 else { return }
        let newIndex = activeTabIndex < tabs.count - 1 ? activeTabIndex + 1 : 0
        switchToTab(at: newIndex)
    }

    /// Switch to a specific tab index.
    func switchToTab(at index: Int) {
        guard index >= 0, index < tabs.count, index != activeTabIndex else { return }

        // Commit any in-progress edit on the old tab
        if activeTab.isEditing {
            activeTab.commitEdit()
        }

        activeTabIndex = index
    }

    // MARK: - Unsaved Changes Confirmation

    func confirmDiscardingChanges(on tab: TabState, action: @escaping () -> Void) {
        guard tab.document.isModified else {
            action()
            return
        }

        let alert = NSAlert()
        alert.messageText = "Do you want to save changes to your document?"
        alert.informativeText = "Your changes will be lost if you don't save them."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Don't Save")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:
            tab.document.save()
            action()
        case .alertSecondButtonReturn:
            action()
        default:
            break
        }
    }

    // MARK: - Safe Document Operations (operate on active tab)

    func safeNewDocument() {
        let tab = activeTab
        confirmDiscardingChanges(on: tab) {
            tab.document.newDocument()
            tab.selectedRow = nil
            tab.selectedColumn = nil
            tab.resetColumnWidths()
        }
    }

    func safeOpenFile() {
        let tab = activeTab
        confirmDiscardingChanges(on: tab) {
            tab.document.openFile {
                tab.selectedRow = nil
                tab.selectedColumn = nil
                tab.resetColumnWidths()
            }
        }
    }

    func safeLoadFile(at url: URL) {
        let tab = activeTab
        confirmDiscardingChanges(on: tab) {
            tab.document.loadFile(at: url)
            tab.selectedRow = nil
            tab.selectedColumn = nil
            tab.resetColumnWidths()
        }
    }
}



