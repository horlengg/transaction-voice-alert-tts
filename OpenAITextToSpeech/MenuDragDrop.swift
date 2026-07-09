//
//  ReorderableMenuView.swift
//  Sample: jiggle-mode drag & drop reorderable menu (grid + list layouts)
//

import SwiftUI
import UniformTypeIdentifiers
import Combine

// MARK: - Model

struct AppMenu: Identifiable, Equatable {
    let id = UUID()
    var menuID: String?
    var menuName: String?
    var iconName: String
    var allowPersonalizeYN: String   // "Y" / "N" — only "Y" items can be dragged
}

// MARK: - ViewModel

final class MenuViewModel: ObservableObject {
    @Published var allMenus: [AppMenu] = [
        AppMenu(menuID: "1", menuName: "Home",     iconName: "house.fill",        allowPersonalizeYN: "Y"),
        AppMenu(menuID: "2", menuName: "Search",   iconName: "magnifyingglass",   allowPersonalizeYN: "Y"),
        AppMenu(menuID: "3", menuName: "Wallet",   iconName: "creditcard.fill",   allowPersonalizeYN: "Y"),
        AppMenu(menuID: "4", menuName: "Settings", iconName: "gearshape.fill",    allowPersonalizeYN: "N"), // locked
        AppMenu(menuID: "5", menuName: "Profile",  iconName: "person.fill",       allowPersonalizeYN: "Y"),
        AppMenu(menuID: "6", menuName: "Alerts",   iconName: "bell.fill",         allowPersonalizeYN: "Y")
    ]
}

// MARK: - Haptic helper

enum HapticFeedback {
    static func light() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

// MARK: - Conditional modifier helper

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Custom NSItemProvider subclass (pre-iOS 18 fallback)
// Mirrors "MYItemProvider" from the original snippet — lets us hook a
// didEnd callback that fires when the drag session finishes, since the
// stock NSItemProvider has no such callback on older OS versions.

final class ReorderItemProvider: NSItemProvider {
    var didEnd: (() -> Void)?
}

// MARK: - Jiggle Effect
//
// A continuous, reliable wiggle — the classic "iOS home screen edit mode"
// look. Uses .repeatForever(autoreverses:) attached directly via
// withAnimation inside onAppear/onChange, rather than relying on a single
// boolean flip to kick off an implicit .animation(value:) — that approach
// is what silently failed to keep animating in the earlier version.

struct JiggleEffect: ViewModifier {
    let isActive: Bool
    var phase: Double = 0

    @State private var rotation: Double = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .onAppear { if isActive { startJiggle() } }
            .onChange(of: isActive) { active in
                if active {
                    startJiggle()
                } else {
                    withAnimation(.easeOut(duration: 0.15)) { rotation = 0 }
                }
            }
    }

    private func startJiggle() {
        // Small random-ish stagger per item (via phase) so a grid of icons
        // doesn't wiggle in perfect unison.
        let delay = phase.truncatingRemainder(dividingBy: 5) * 0.02
        let angle: Double = 1.7

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard isActive else { return }
            withAnimation(
                .easeInOut(duration: 0.14)
                    .repeatForever(autoreverses: true)
            ) {
                rotation = angle
            }
        }
    }
}

// MARK: - Drop Delegate

struct GridDropDelegate: DropDelegate {
    let item: AppMenu
    @Binding var listData: [AppMenu]
    @Binding var draggingItem: AppMenu?
    @Binding var hasMoved: Bool
    @Binding var isJiggle: Bool

    // Guards against dropEntered firing again (with now-stale indices)
    // while the previous move's animation is still in flight. This is
    // what fixes the "wrong index" / crash-on-drop issue.
    @Binding var isReordering: Bool

    func dropEntered(info: DropInfo) {
        guard !isReordering else { return }

        guard let draggingItem,
              draggingItem != item,
              let fromIndex = listData.firstIndex(of: draggingItem),
              let toIndex = listData.firstIndex(of: item),
              fromIndex != toIndex else { return }

        hasMoved = true
        isReordering = true

        withAnimation(.default) {
            listData.move(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }

        // Unlock once this move's animation has settled so the *next*
        // dropEntered recomputes fresh indices instead of racing this one.
        // 0.35s comfortably covers the .default animation duration — bump
        // this if you use a longer custom animation.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isReordering = false
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        // Reset drag state once the drop completes.
        draggingItem = nil
        isReordering = false
        hasMoved = false
        return true
    }
}

// MARK: - Main View

struct ReorderableMenuView: View {
    @StateObject private var vm = MenuViewModel()

    @State private var isGrid = true
    @State private var draggingItem: AppMenu?
    @State private var hasMoved = false

    // Reorder ("jiggle") mode is now independent of the drag gesture itself —
    // entered via long-press, exited via the Done button. This is what
    // actually drives the wiggle animation.
    @State private var isJiggle = false
    @State private var isReordering = false

    private let gridColumns = [
        GridItem(.adaptive(minimum: 80), spacing: 16)
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("Layout", selection: $isGrid) {
                    Text("Grid").tag(true)
                    Text("List").tag(false)
                }
                .pickerStyle(.segmented)

                if isJiggle {
                    Button("Done") {
                        withAnimation { isJiggle = false }
                    }
                    .fontWeight(.semibold)
                    .padding(.leading, 8)
                }
            }
            .padding()

            ScrollView {
                if isGrid {
                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(vm.allMenus) { menu in
                            menuCell(for: menu)
                        }
                    }
                    .padding()
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(vm.allMenus) { menu in
                            menuCell(for: menu)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - Cell

    @ViewBuilder
    private func menuCell(for appMenu: AppMenu) -> some View {
        Group {
            if isGrid {
                gridItemView(appMenu)
            } else {
                listItemView(appMenu)
            }
        }
        // Wiggle only draggable items, and only while reorder mode is on.
        .modifier(
            JiggleEffect(
                isActive: isJiggle && appMenu.allowPersonalizeYN == "Y",
                // Slight per-item phase offset so icons don't all wiggle
                // in perfect lockstep like a robot marching band.
                phase: Double(vm.allMenus.firstIndex(of: appMenu) ?? 0)
            )
        )
        // Long-press ANY personalizable item to enter reorder mode —
        // this is what actually turns the wiggle on now, independent
        // of the drag gesture itself.
        .if(appMenu.allowPersonalizeYN == "Y") { view in
            view
                .onLongPressGesture(minimumDuration: 0.4) {
                    HapticFeedback.light()
                    withAnimation { isJiggle = true }
                }
                .onDrag {
                    draggingItem = appMenu
                    hasMoved = false

                    if #available(iOS 18.0, *) {
                        return NSItemProvider(object: (appMenu.menuID ?? "") as NSString)
                    } else {
                        let provider = ReorderItemProvider(object: (appMenu.menuID ?? "") as NSString)
                        provider.didEnd = {
                            DispatchQueue.main.async {
                                draggingItem = nil
                            }
                        }
                        return provider
                    }
                } preview: {
                    dragPreview(for: appMenu)
                }
        }
        .onDrop(
            of: [.text],
            delegate: GridDropDelegate(
                item: appMenu,
                listData: $vm.allMenus,
                draggingItem: $draggingItem,
                hasMoved: $hasMoved,
                isJiggle: $isJiggle,
                isReordering: $isReordering
            )
        )
    }

    // MARK: - Grid layout item

    private func gridItemView(_ appMenu: AppMenu) -> some View {
        VStack(spacing: 6) {
            Image(systemName: appMenu.iconName)
                .font(.system(size: 26))
                .frame(width: 56, height: 56)
                .background(Color.blue.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            Text(appMenu.menuName ?? "")
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .opacity(appMenu.allowPersonalizeYN == "Y" ? 1 : 0.5)
    }

    // MARK: - List layout item

    private func listItemView(_ appMenu: AppMenu) -> some View {
        HStack(spacing: 12) {
            Image(systemName: appMenu.iconName)
                .frame(width: 28, height: 28)

            Text(appMenu.menuName ?? "")
                .font(.subheadline)
                .fontWeight(.semibold)

            Spacer()

            if appMenu.allowPersonalizeYN != "Y" {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(appMenu.allowPersonalizeYN == "Y" ? 1 : 0.6)
    }

    // MARK: - Drag preview

    @ViewBuilder
    private func dragPreview(for appMenu: AppMenu) -> some View {
        if isGrid {
            Image(systemName: appMenu.iconName)
                .font(.system(size: 26))
                .frame(width: 70, height: 70)
                .background(Color.blue.opacity(0.25))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 26))
        } else {
            HStack(spacing: 6) {
                Image(systemName: appMenu.iconName)
                    .frame(width: 22, height: 22)
                Text(appMenu.menuName ?? "")
                    .font(.footnote)
                    .fontWeight(.bold)
            }
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Preview

#Preview {
    ReorderableMenuView()
}
