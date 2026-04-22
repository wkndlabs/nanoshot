//
//  Shortcut.swift
//  Nanoshot
//

import AppKit
import Carbon.HIToolbox

struct Shortcut: Codable, Equatable, Hashable {
    var keyCode: UInt32
    var modifiers: UInt32  // Carbon modifier mask (cmdKey, shiftKey, optionKey, controlKey)

    var displayString: String {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(optionKey)  != 0 { parts.append("⌥") }
        if modifiers & UInt32(shiftKey)   != 0 { parts.append("⇧") }
        if modifiers & UInt32(cmdKey)     != 0 { parts.append("⌘") }
        parts.append(Shortcut.keyString(for: keyCode))
        return parts.joined()
    }

    init(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    init?(event: NSEvent) {
        guard event.type == .keyDown else { return nil }
        var mods: UInt32 = 0
        let flags = event.modifierFlags
        if flags.contains(.command) { mods |= UInt32(cmdKey) }
        if flags.contains(.shift)   { mods |= UInt32(shiftKey) }
        if flags.contains(.option)  { mods |= UInt32(optionKey) }
        if flags.contains(.control) { mods |= UInt32(controlKey) }
        self.keyCode = UInt32(event.keyCode)
        self.modifiers = mods
    }

    static func keyString(for keyCode: UInt32) -> String {
        let map: [Int: String] = [
            kVK_ANSI_A: "A", kVK_ANSI_B: "B", kVK_ANSI_C: "C", kVK_ANSI_D: "D",
            kVK_ANSI_E: "E", kVK_ANSI_F: "F", kVK_ANSI_G: "G", kVK_ANSI_H: "H",
            kVK_ANSI_I: "I", kVK_ANSI_J: "J", kVK_ANSI_K: "K", kVK_ANSI_L: "L",
            kVK_ANSI_M: "M", kVK_ANSI_N: "N", kVK_ANSI_O: "O", kVK_ANSI_P: "P",
            kVK_ANSI_Q: "Q", kVK_ANSI_R: "R", kVK_ANSI_S: "S", kVK_ANSI_T: "T",
            kVK_ANSI_U: "U", kVK_ANSI_V: "V", kVK_ANSI_W: "W", kVK_ANSI_X: "X",
            kVK_ANSI_Y: "Y", kVK_ANSI_Z: "Z",
            kVK_ANSI_0: "0", kVK_ANSI_1: "1", kVK_ANSI_2: "2", kVK_ANSI_3: "3",
            kVK_ANSI_4: "4", kVK_ANSI_5: "5", kVK_ANSI_6: "6", kVK_ANSI_7: "7",
            kVK_ANSI_8: "8", kVK_ANSI_9: "9",
            kVK_ANSI_Minus: "-", kVK_ANSI_Equal: "=",
            kVK_ANSI_LeftBracket: "[", kVK_ANSI_RightBracket: "]",
            kVK_ANSI_Semicolon: ";", kVK_ANSI_Quote: "'",
            kVK_ANSI_Comma: ",", kVK_ANSI_Period: ".",
            kVK_ANSI_Slash: "/", kVK_ANSI_Backslash: "\\", kVK_ANSI_Grave: "`",
            kVK_Space: "Space", kVK_Return: "↩", kVK_Tab: "⇥",
            kVK_Delete: "⌫", kVK_ForwardDelete: "⌦", kVK_Escape: "⎋",
            kVK_LeftArrow: "←", kVK_RightArrow: "→",
            kVK_UpArrow: "↑", kVK_DownArrow: "↓",
            kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4",
            kVK_F5: "F5", kVK_F6: "F6", kVK_F7: "F7", kVK_F8: "F8",
            kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
        ]
        return map[Int(keyCode)] ?? "?"
    }

    static let defaultRegion = Shortcut(keyCode: UInt32(kVK_ANSI_4), modifiers: UInt32(cmdKey | shiftKey))
    static let defaultScreen = Shortcut(keyCode: UInt32(kVK_ANSI_3), modifiers: UInt32(cmdKey | shiftKey))
    static let defaultWindow = Shortcut(keyCode: UInt32(kVK_ANSI_5), modifiers: UInt32(cmdKey | shiftKey))
}

@MainActor
final class HotkeyManager {
    static let shared = HotkeyManager()

    private struct Registration {
        let id: UInt32
        let ref: EventHotKeyRef?
        let handler: () -> Void
    }

    private var registrations: [String: Registration] = [:]
    private var nextID: UInt32 = 1
    private var handlerInstalled = false

    private init() {}

    func register(key: String, shortcut: Shortcut?, handler: @escaping () -> Void) {
        unregister(key: key)
        installHandlerIfNeeded()

        guard let shortcut = shortcut else { return }

        let id = nextID
        nextID += 1
        let hkID = EventHotKeyID(signature: 0x4E414E4F /* 'NANO' */, id: id)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hkID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        if status == noErr {
            registrations[key] = Registration(id: id, ref: ref, handler: handler)
        }
    }

    func unregister(key: String) {
        if let reg = registrations[key], let ref = reg.ref {
            UnregisterEventHotKey(ref)
        }
        registrations.removeValue(forKey: key)
    }

    /// Tears down every registered hotkey. Used while a ShortcutRecorder is capturing
    /// keys so the global hotkey doesn't fire before the local monitor sees the event.
    func unregisterAll() {
        for (_, reg) in registrations {
            if let ref = reg.ref { UnregisterEventHotKey(ref) }
        }
        registrations.removeAll()
    }

    fileprivate func fire(id: UInt32) {
        if let reg = registrations.values.first(where: { $0.id == id }) {
            reg.handler()
        }
    }

    private func installHandlerIfNeeded() {
        guard !handlerInstalled else { return }
        handlerInstalled = true

        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let event = event, let userData = userData else {
                    return OSStatus(eventNotHandledErr)
                }
                var hkID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hkID
                )
                let id = hkID.id
                DispatchQueue.main.async {
                    let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                    manager.fire(id: id)
                }
                return noErr
            },
            1,
            &spec,
            selfPtr,
            nil
        )
    }
}
