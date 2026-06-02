import Foundation

enum Formatters {
    static func integer(_ value: Int) -> String {
        value.formatted(.number)
    }

    static func compactInteger(_ value: Int) -> String {
        value.formatted(.number.notation(.compactName))
    }

    static func percent(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(1))))%"
    }

    static func time(_ date: Date) -> String {
        date.formatted(.dateTime.hour().minute())
    }
}
