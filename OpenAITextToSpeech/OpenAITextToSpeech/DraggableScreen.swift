import SwiftUI
import UniformTypeIdentifiers

// MARK: - Model

struct GridMenuItem: Identifiable, Codable, Equatable, Transferable {
    var id: UUID = UUID()
    var title: String
    var icon: String
    var color: String // hex or named color

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .gridMenuItem)
    }
}

extension UTType {
    static let gridMenuItem = UTType(exportedAs: "com.example.gridmenuitem")
}

// MARK: - Drag & Drop Grid Menu

struct DragDropGridMenu: View {
    @State private var items: [GridMenuItem] = [
        GridMenuItem(title: "Home", icon: "house.fill", color: "blue"),
        GridMenuItem(title: "Search", icon: "magnifyingglass", color: "orange"),
        GridMenuItem(title: "Favorites", icon: "heart.fill", color: "pink"),
        GridMenuItem(title: "Settings", icon: "gearshape.fill", color: "gray"),
        GridMenuItem(title: "Profile", icon: "person.crop.circle.fill", color: "purple"),
        GridMenuItem(title: "Camera", icon: "camera.fill", color: "teal"),
        GridMenuItem(title: "Photos", icon: "photo.fill", color: "green"),
        GridMenuItem(title: "Mail", icon: "envelope.fill", color: "indigo"),
        GridMenuItem(title: "Music", icon: "music.note", color: "red")
    ]

    @State private var draggingItem: GridMenuItem?

    private let columns = [
        GridItem(.adaptive(minimum: 90), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(items) { item in
                    tile(for: item)
                        .draggable(item) {
                            tilePreview(for: item)
                                .onAppear { draggingItem = item }
                        }
                        .dropDestination(for: GridMenuItem.self) { droppedItems, _ in
                            handleDrop(droppedItems, onto: item)
                        } isTargeted: { isTargeted in
                            if isTargeted { reorderLive(onto: item) }
                        }
                }
            }
            .padding()
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: items)
        }
        .navigationTitle("Grid Menu")
    }

    // MARK: - Tile

    private func tile(for item: GridMenuItem) -> some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 16)
                .fill(color(item.color).gradient)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: item.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                )
            Text(item.title)
                .font(.caption)
                .lineLimit(1)
        }
        .frame(width: 90)
        .opacity(draggingItem == item ? 0.3 : 1.0)
        .scaleEffect(draggingItem == item ? 0.9 : 1.0)
    }

    private func tilePreview(for item: GridMenuItem) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(color(item.color).gradient)
            .frame(width: 60, height: 60)
            .overlay(
                Image(systemName: item.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            )
    }

    // MARK: - Drag Logic

    /// Live-reorder as the dragged item hovers over another tile (home-screen style).
    private func reorderLive(onto targetItem: GridMenuItem) {
        guard let dragging = draggingItem,
              dragging != targetItem,
              let fromIndex = items.firstIndex(of: dragging),
              let toIndex = items.firstIndex(of: targetItem) else { return }

        withAnimation {
            items.move(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: fromIndex < toIndex ? toIndex + 1 : toIndex
            )
        }
    }

    /// Final drop just clears drag state; the move already happened live.
    private func handleDrop(_ droppedItems: [GridMenuItem], onto targetItem: GridMenuItem) -> Bool {
        defer { draggingItem = nil }
        return droppedItems.first != nil
    }

    private func color(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "orange": return .orange
        case "pink": return .pink
        case "gray": return .gray
        case "purple": return .purple
        case "teal": return .teal
        case "green": return .green
        case "indigo": return .indigo
        case "red": return .red
        default: return .accentColor
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DragDropGridMenu()
    }
}
