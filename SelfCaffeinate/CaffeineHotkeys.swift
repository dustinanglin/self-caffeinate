import AppKit
import Carbon

/// Global Ctrl+Option+= / Ctrl+Option+- hotkeys (works while unfocused; no Accessibility prompt).
final class CaffeineHotkeys {
    private static let signature: OSType = 0x4341_4646 // 'CAFF'
    private static let increaseID: UInt32 = 1
    private static let decreaseID: UInt32 = 2

    private weak var caffeine: CaffeineController?
    private var handlerRef: EventHandlerRef?
    private var increaseHotKey: EventHotKeyRef?
    private var decreaseHotKey: EventHotKeyRef?
    private var keypadIncreaseHotKey: EventHotKeyRef?
    private var keypadDecreaseHotKey: EventHotKeyRef?

    func install(caffeine: CaffeineController) {
        self.caffeine = caffeine
        uninstall()

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let userData = Unmanaged.passUnretained(self).toOpaque()
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData, let event else { return noErr }
                let hotkeys = Unmanaged<CaffeineHotkeys>.fromOpaque(userData).takeUnretainedValue()
                return hotkeys.handle(event)
            },
            1,
            &eventType,
            userData,
            &handlerRef
        )
        guard status == noErr else { return }

        let mods = UInt32(controlKey | optionKey)
        // '=' key is the unshifted '+' key; also register keypad ±.
        register(keyCode: UInt32(kVK_ANSI_Equal), modifiers: mods, id: Self.increaseID, into: &increaseHotKey)
        register(keyCode: UInt32(kVK_ANSI_Minus), modifiers: mods, id: Self.decreaseID, into: &decreaseHotKey)
        register(keyCode: UInt32(kVK_ANSI_KeypadPlus), modifiers: mods, id: Self.increaseID, into: &keypadIncreaseHotKey)
        register(keyCode: UInt32(kVK_ANSI_KeypadMinus), modifiers: mods, id: Self.decreaseID, into: &keypadDecreaseHotKey)
    }

    func uninstall() {
        if let increaseHotKey { UnregisterEventHotKey(increaseHotKey) }
        if let decreaseHotKey { UnregisterEventHotKey(decreaseHotKey) }
        if let keypadIncreaseHotKey { UnregisterEventHotKey(keypadIncreaseHotKey) }
        if let keypadDecreaseHotKey { UnregisterEventHotKey(keypadDecreaseHotKey) }
        increaseHotKey = nil
        decreaseHotKey = nil
        keypadIncreaseHotKey = nil
        keypadDecreaseHotKey = nil

        if let handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
    }

    deinit {
        uninstall()
    }

    private func register(
        keyCode: UInt32,
        modifiers: UInt32,
        id: UInt32,
        into ref: inout EventHotKeyRef?
    ) {
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: Self.signature, id: id)
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        if status == noErr {
            ref = hotKeyRef
        }
    }

    private func handle(_ event: EventRef) -> OSStatus {
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )
        guard status == noErr, hotKeyID.signature == Self.signature else { return noErr }

        DispatchQueue.main.async { [weak self] in
            switch hotKeyID.id {
            case Self.increaseID:
                self?.caffeine?.increase()
            case Self.decreaseID:
                self?.caffeine?.decrease()
            default:
                break
            }
        }
        return noErr
    }
}
