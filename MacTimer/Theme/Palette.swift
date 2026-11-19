import SwiftUI

struct Palette {
    let background: Color
    let surface: Color
    let text: Color
    let secondary: Color
    let accent: Color
    let onAccent: Color
    let track: Color

    static let dark = Palette(
        background: Color(hex: 0x17191D),
        surface: Color(hex: 0x24272D),
        text: Color(hex: 0xF5F5F5),
        secondary: Color(hex: 0xA1A6B0),
        accent: Color(hex: 0x84A9FF),
        onAccent: Color(hex: 0x172033),
        track: Color(hex: 0x343841)
    )

    static let light = Palette(
        background: Color(hex: 0xF8F9FB),
        surface: Color(hex: 0xFFFFFF),
        text: Color(hex: 0x20232A),
        secondary: Color(hex: 0x737985),
        accent: Color(hex: 0x5577D8),
        onAccent: Color.white,
        track: Color(hex: 0xE6E8EE)
    )
}

extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}
