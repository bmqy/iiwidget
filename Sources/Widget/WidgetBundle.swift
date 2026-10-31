import WidgetKit
import SwiftUI

@main
struct WidgetStudioWidgetBundle: WidgetBundle {
    var body: some Widget {
        TextCardWidget()
        CounterWidget()
        ShiftCalendarWidget()
    }
}
