//
//  PinView.swift
//  OpenAITextToSpeech
//
//  Created by Houleng.LY on 3/7/26.
//

import SwiftUI

struct PinView: View {
    
    @State private var pin = ""
    @State private var firstDraw = true
    @EnvironmentObject var router : Router
    
    var body: some View {
        
        VStack {
//            Spacer()
            PinDotsView(pin: pin)
            Spacer()
                .frame(height: 60)
            KeypadView(action : handleKeyPress)
        }
    }
    
    private func handleKeyPress(_ key: KeypadKey) {
        switch key {
        case .clear:
            pin = ""
        case .backspace:
            pin.removeLast()
        default:
            
            pin += key.id
            
            if pin.count == 4 {
                router.pop()
            }
            
            
            
        }
    }
    
    
}

struct PinDotsView: View {
    let pin: String
    @State private var visible: [Bool] = [false, false, false, false]
    
    var body: some View {
        HStack(spacing: 15) {
            ForEach(0..<4, id: \.self) { index in
                dotView(for: index)
            }
        }
        .task {
            await animateInSequence()
        }
    }
    
    @ViewBuilder
    private func dotView(for index: Int) -> some View {
        let active: Bool = pin.count > index
        let isVisible: Bool = visible[index]
    
        VStack {
            Circle()
                .foregroundColor(active ? .green : .gray)
                .frame(width: 20, height: 20)
                .phaseAnimator([1.0, 1.3, 1.0], trigger: active) { content, phase in
                    content
                        .scaleEffect(active ? phase : 1.0)
                } animation: { phase in
                    .spring(response: 0.3, dampingFraction: 0.5)
                }
        }
        .offset(y:isVisible ? 0 : 10)
        .opacity(isVisible ? 1 : 0)
        .animation(.easeOut(duration: 0.3), value: isVisible)
    }
    private func animateInSequence() async {
        for index in 0..<visible.count {
            visible[index] = true
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }
}



struct KeypadView: View {
    let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 3)
    
    var action : (_ key : KeypadKey) -> Void
    
    init(action: @escaping (_ key : KeypadKey) -> Void) {
        self.action = action
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(KeypadKey.allCases) { key in
                ZStack {
                    Button(action: {
                        action(key)
                    }) {
                        Text(key.rawValue)
                            .font(.system(size: 28))
                            .foregroundColor(key.foregroundColor)
                            .frame(maxWidth: .infinity, minHeight: 90)
                            .background(Color.white)
                    }
                }
            }
        }
        .overlay(KeypadGridBorder(rows: 4, columns: 3))
    }
}

struct KeypadGridBorder: View {
    let rows: Int
    let columns: Int
    let lineWidth: CGFloat = 0.5

    var body: some View {
        
        GeometryReader { geo in
            let cellW = geo.size.width / CGFloat(columns)
            let cellH = geo.size.height / CGFloat(rows)
            
            let borderColors : [Color] = [
                .clear,
                .gray.opacity(0.7),
                .gray.opacity(0.7),
                .clear
            ]

            ZStack {
                // Horizontal lines — fade left to right
                Path { path in
                    for r in 1..<rows {
                        let y = CGFloat(r) * cellH
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: borderColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: lineWidth
                )

                // Vertical lines — fade top to bottom
                Path { path in
                    for c in 1..<columns {
                        let x = CGFloat(c) * cellW
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: borderColors,
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: lineWidth
                )
            }
        }
        .allowsHitTesting(false)
    }
}



enum KeypadKey: String, CaseIterable, Identifiable {
    case one = "1"
    case two = "2"
    case three = "3"
    case four = "4"
    case five = "5"
    case six = "6"
    case seven = "7"
    case eight = "8"
    case nine = "9"
    case clear = "C"
    case zero = "0"
    case backspace = "⌫"
    
    var id: String { self.rawValue }
    
    var columnIndex: Int {
        let allCases = KeypadKey.allCases
        guard let index = allCases.firstIndex(of: self) else { return 0 }
        return index % 3
    }
    
    var rowIndex: Int {
        let allCases = KeypadKey.allCases
        guard let index = allCases.firstIndex(of: self) else { return 0 }
        return index / 3
    }
    
    var foregroundColor: Color {
        switch self {
//        case .clear: return .red // Example: make clear button red
        default: return .black
        }
    }
}

#Preview {
    PinView()
}
