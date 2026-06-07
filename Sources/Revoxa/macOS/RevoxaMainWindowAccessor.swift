#if os(macOS)
import AppKit
import SwiftUI

private struct RevoxaMainWindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            if let window = view.window {
                RevoxaWindowConfigurator.configure(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                RevoxaWindowConfigurator.configure(window)
            }
        }
    }
}

extension View {
    func configureRevoxaMainWindow() -> some View {
        background(RevoxaMainWindowAccessor())
    }
}
#else
import SwiftUI

extension View {
    func configureRevoxaMainWindow() -> some View {
        self
    }
}
#endif
