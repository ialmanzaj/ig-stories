//
//  Trapezoid.swift
//  InstaStory
//
//  Created by Isaac on 09/27/25.
//

import SwiftUI

// Rectángulo simple (topInset = 0)
struct Trapezoid: Shape {
    var topInset: CGFloat
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: 0, y: r.minY))
        p.closeSubpath()
        return p
    }
}

/// Fase 1 LIFO: el **último en caer queda arriba del stack** (primero en el stack).
/// Slots fijos invisibles + un único bloque volador posicionado por coordenadas absolutas.
/// Sin rebotes. Sin solapes.
struct Phase1NoOverlapLIFOView: View {
    private let levels = 3
    private let blockHeight: CGFloat = 72
    private let landingGap: CGFloat = 120
    private let fallDuration: Double = 1.0
    private let settlePause: Double = 0.05
    private var fallAnim: Animation { .linear(duration: fallDuration) } // sin rebote

    // Colores base→arriba
    private let colorsBottomToTop: [Color] = [
        Color(red: 0.357, green: 0.227, blue: 0.122), // base
        Color(red: 0.714, green: 0.514, blue: 0.365), // medio
        Color(red: 0.545, green: 0.588, blue: 0.624)  // tope
    ]

    @State private var slotVisible = Array(repeating: false, count: 3)

    // Bloque volador (posición absoluta)
    @State private var flyVisible: Bool = false
    @State private var flyColor: Color = .clear
    @State private var flyCenterY: CGFloat = -2000

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let h = g.size.height

            // Centros Y de los slots por índice de base (0=base, 1=medio, 2=tope)
            let slotCentersY: [CGFloat] = (0..<levels).map { idxBottom in
                let stackBottomY = h - landingGap
                return stackBottomY - (CGFloat(idxBottom) + 0.5) * blockHeight
            }

            ZStack {
                // Slots fijos (reservan espacio desde el inicio)
                ForEach(0..<levels, id: \.self) { idxBottom in
                    Trapezoid(topInset: 0)
                        .fill(colorsBottomToTop[idxBottom])
                        .frame(width: w, height: blockHeight)
                        .position(x: w / 2, y: slotCentersY[idxBottom])
                        .opacity(slotVisible[idxBottom] ? 1 : 0)
                }

                // Bloque volador
                Trapezoid(topInset: 0)
                    .fill(flyColor)
                    .frame(width: w, height: blockHeight)
                    .position(x: w / 2, y: flyCenterY)
                    .opacity(flyVisible ? 1 : 0)
            }
            .background(Color(red: 0.09, green: 0.06, blue: 0.15))
            .ignoresSafeArea()
            .onAppear {
                Task { @MainActor in
                    // LIFO: i=0 cae a BASE (idxBottom=0), i=1 a MEDIO (1), i=2 a TOPE (2).
                    for i in 0..<levels {
                        let targetIdxBottom = i            // ← cambio clave: último en caer va arriba
                        flyColor = colorsBottomToTop[targetIdxBottom]
                        flyCenterY = -blockHeight          // parte fuera de pantalla
                        flyVisible = true

                        withAnimation(fallAnim) {
                            flyCenterY = slotCentersY[targetIdxBottom]
                        }
                        try? await Task.sleep(nanoseconds: UInt64(fallDuration * 1_000_000_000))

                        var t = Transaction(); t.disablesAnimations = true
                        withTransaction(t) {
                            slotVisible[targetIdxBottom] = true
                            flyVisible = false
                        }
                        try? await Task.sleep(nanoseconds: UInt64(settlePause * 1_000_000_000))
                    }
                }
            }
        }
    }
}

// Demo
struct ContentView: View {
    var body: some View { Phase1NoOverlapLIFOView().ignoresSafeArea() }
}

#Preview { ContentView() }
