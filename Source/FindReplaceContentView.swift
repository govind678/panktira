//
//  FindReplaceContentView.swift
//  Panktira
//

import SwiftUI

/// An inline find & replace toolbar displayed below the main toolbar.
struct FindReplaceContentView: View {
    @Bindable var tabState: TabState
    @FocusState private var findFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                // Find field
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 11))

                    TextField("Find…", text: $tabState.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .focused($findFieldFocused)
                        .onSubmit { tabState.findNext() }
                        .frame(minWidth: 100, maxWidth: 180)

                    if !tabState.searchText.isEmpty {
                        Text(matchCountText)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .fixedSize()
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(.background, in: RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.gray.opacity(0.25), lineWidth: 0.5)
                )

                // Replace field
                HStack(spacing: 4) {
                    Image(systemName: "arrow.2.squarepath")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 11))

                    TextField("Replace…", text: $tabState.replaceText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .onSubmit { tabState.replaceCurrent() }
                        .frame(minWidth: 100, maxWidth: 180)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(.background, in: RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.gray.opacity(0.25), lineWidth: 0.5)
                )

                // Navigation buttons
                Button { tabState.findPrevious() } label: {
                    Image(systemName: "chevron.up")
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .help("Previous Match (⇧⌘G)")

                Button { tabState.findNext() } label: {
                    Image(systemName: "chevron.down")
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .help("Next Match (⌘G)")

                Divider()
                    .frame(height: 16)

                // Replace buttons
                Button("Replace") {
                    tabState.replaceCurrent()
                }
                .disabled(tabState.searchResults.isEmpty)

                Button("All") {
                    tabState.replaceAll()
                }
                .disabled(tabState.searchResults.isEmpty)

                Divider()
                    .frame(height: 16)

                // Options
                Picker("", selection: $tabState.searchOptions.matchMode) {
                    ForEach(MatchMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .fixedSize()
                .labelsHidden()

                Toggle(isOn: $tabState.searchOptions.caseSensitive) {
                    Text("Aa")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                }
                .toggleStyle(.button)
                .help("Case Sensitive")

                Toggle(isOn: $tabState.searchOptions.wrapAround) {
                    Image(systemName: "repeat")
                        .font(.system(size: 10))
                }
                .toggleStyle(.button)
                .help("Wrap Around")

                Spacer()

                // Dismiss
                Button { tabState.dismissFind() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close Find Bar (Esc)")
            }
            .controlSize(.small)
            .buttonStyle(.borderless)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(.regularMaterial)

            Divider()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                findFieldFocused = true
            }
        }
        .onChange(of: tabState.searchText) { _, _ in
            tabState.performSearch()
        }
        .onChange(of: tabState.searchOptions.matchMode) { _, _ in
            tabState.performSearch()
        }
        .onChange(of: tabState.searchOptions.caseSensitive) { _, _ in
            tabState.performSearch()
        }
        .onExitCommand {
            tabState.dismissFind()
        }
    }

    private var matchCountText: String {
        if tabState.searchResults.isEmpty {
            return "No results"
        }
        return "\(tabState.currentSearchIndex + 1) of \(tabState.searchResults.count)"
    }
}
