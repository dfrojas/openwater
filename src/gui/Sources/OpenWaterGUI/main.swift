import SwiftUI
import OpenWaterBridge
import AppKit


@main
struct OpenWaterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 800, height: 600)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct ContentView: View {
    @State private var isHovering = false
    
    var body: some View {
        VStack {
            Text("OpenWater Dive Log")
                .font(.title)
                .padding()
            
            Button("Parse UDDF") {
                print(OpenWaterBridge.openWaterInit())
            }
            .buttonStyle(.bordered)
            .onHover { hovering in
                isHovering = hovering
            }
        }
        .frame(minWidth: 400, minHeight: 300)
        .padding()
    }
}