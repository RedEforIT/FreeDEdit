import AppKit
import CoreFoundation
import UniformTypeIdentifiers

@main
enum FreeDEditApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private weak var recentDocumentsMenu: NSMenu?
    private weak var launchOpenPanel: NSOpenPanel?
    private var launchPanelRequestedNewDocument = false
    private var launchPanelRequestedSettings = false
    func applicationDidFinishLaunching(_ notification: Notification) {
        installMainMenu()
        DispatchQueue.main.async { [weak self] in
            guard NSDocumentController.shared.documents.isEmpty else { return }
            self?.presentLaunchOpenPanel()
        }
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool { false }
    func applicationShouldSaveApplicationState(_ app: NSApplication) -> Bool { true }
    func applicationShouldRestoreApplicationState(_ app: NSApplication) -> Bool { true }
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }

    @MainActor
    private func installMainMenu() {
        let main = NSMenu()
        let appMenuItem = NSMenuItem()
        main.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About FreeDEdit", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(showSettingsWindow(_:)), keyEquivalent: ",")
        settingsItem.target = self
        appMenu.addItem(settingsItem)
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Services", action: nil, keyEquivalent: "")
        appMenu.items.last?.submenu = NSApplication.shared.servicesMenu
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide FreeDEdit", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit FreeDEdit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu

        let fileItem = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        let fileMenu = NSMenu(title: "File")
        let newItem = NSMenuItem(title: "New", action: #selector(newDocument(_:)), keyEquivalent: "n")
        newItem.target = self
        fileMenu.addItem(newItem)
        let openItem = NSMenuItem(title: "Open…", action: #selector(openDocument(_:)), keyEquivalent: "o")
        openItem.target = self
        fileMenu.addItem(openItem)
        let recentItem = NSMenuItem(title: "Open Recent", action: nil, keyEquivalent: "")
        let recentMenu = NSMenu(title: "Open Recent")
        recentMenu.delegate = self
        recentDocumentsMenu = recentMenu
        recentItem.submenu = recentMenu
        fileMenu.addItem(recentItem)
        fileMenu.addItem(.separator())
        fileMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileMenu.addItem(withTitle: "Duplicate", action: #selector(NSDocument.duplicate(_:)), keyEquivalent: "")
        fileMenu.addItem(.separator())
        fileMenu.addItem(withTitle: "Save", action: #selector(NSDocument.save(_:)), keyEquivalent: "s")
        fileMenu.addItem(withTitle: "Save As…", action: #selector(NSDocument.saveAs(_:)), keyEquivalent: "S")
        fileMenu.addItem(withTitle: "Rename…", action: #selector(NSDocument.rename(_:)), keyEquivalent: "")
        fileMenu.addItem(withTitle: "Move To…", action: #selector(NSDocument.move(_:)), keyEquivalent: "")
        fileMenu.addItem(withTitle: "Revert to Saved", action: Selector("revertDocumentToSaved:"), keyEquivalent: "")
        fileMenu.addItem(withTitle: "Browse All Versions…", action: #selector(NSDocument.browseVersions(_:)), keyEquivalent: "")
        fileMenu.addItem(withTitle: "Export as PDF…", action: #selector(TextDocument.exportPDF(_:)), keyEquivalent: "")
        fileMenu.addItem(.separator())
        fileMenu.addItem(withTitle: "Page Setup…", action: Selector("runPageLayout:"), keyEquivalent: "")
        fileMenu.addItem(withTitle: "Print…", action: #selector(TextDocument.printCurrentDocument(_:)), keyEquivalent: "p")
        main.addItem(fileItem)
        fileItem.submenu = fileMenu

        let editItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        let editMenu = NSMenu(title: "Edit")
        editMenu.delegate = self
        let undoItem = NSMenuItem(title: "Undo", action: #selector(undo(_:)), keyEquivalent: "z")
        undoItem.target = self
        editMenu.addItem(undoItem)
        let redoItem = NSMenuItem(title: "Redo", action: #selector(redo(_:)), keyEquivalent: "Z")
        redoItem.target = self
        editMenu.addItem(redoItem)
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Paste and Match Style", action: Selector("pasteAsPlainText:"), keyEquivalent: "")
        editMenu.addItem(withTitle: "Delete", action: Selector("delete:"), keyEquivalent: "")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        let insertBreaks = NSMenuItem(title: "Insert", action: nil, keyEquivalent: "")
        let breakMenu = NSMenu(title: "Insert")
        for (title, selector) in [("Line Break", "insertLineBreak:"), ("Paragraph Break", "insertNewline:"), ("Page Break", "insertPageBreak:")] {
            breakMenu.addItem(withTitle: title, action: Selector(selector), keyEquivalent: "")
        }
        insertBreaks.submenu = breakMenu
        editMenu.addItem(insertBreaks)
        editMenu.addItem(withTitle: "Insert Table", action: #selector(TextDocument.insertTable(_:)), keyEquivalent: "")
        editMenu.addItem(withTitle: "Attach Files…", action: #selector(TextDocument.insertAttachment(_:)), keyEquivalent: "")
        editMenu.addItem(withTitle: "Add Link…", action: #selector(TextDocument.insertLink(_:)), keyEquivalent: "k")
        let findItem = NSMenuItem(title: "Find", action: nil, keyEquivalent: "")
        let findMenu = NSMenu(title: "Find")
        for (title, action, key, tag) in [("Find…", "performFindPanelAction:", "f", NSFindPanelAction.showFindPanel.rawValue), ("Find Next", "performFindPanelAction:", "g", NSFindPanelAction.next.rawValue), ("Find Previous", "performFindPanelAction:", "G", NSFindPanelAction.previous.rawValue), ("Use Selection for Find", "performFindPanelAction:", "e", NSFindPanelAction.setFindString.rawValue), ("Jump to Selection", "centerSelectionInVisibleArea:", "j", 0), ("Select Line…", "selectLine:", "", 0)] {
            let item = NSMenuItem(title: title, action: Selector(action), keyEquivalent: key)
            item.tag = Int(tag)
            findMenu.addItem(item)
        }
        findItem.submenu = findMenu
        let replaceItem = NSMenuItem(title: "Find and Replace…", action: #selector(showFindReplace(_:)), keyEquivalent: "")
        replaceItem.target = self
        editMenu.addItem(replaceItem)
        editMenu.addItem(.separator())
        editMenu.addItem(findItem)
        let spellingItem = NSMenuItem(title: "Spelling and Grammar", action: nil, keyEquivalent: "")
        let spellingMenu = NSMenu(title: "Spelling and Grammar")
        for (title, selector) in [("Show Spelling and Grammar", "showGuessPanel:"), ("Check Document Now", "checkSpelling:"), ("Check Spelling While Typing", "toggleContinuousSpellChecking:"), ("Check Grammar With Spelling", "toggleGrammarChecking:"), ("Correct Spelling Automatically", "toggleAutomaticSpellingCorrection:")] {
            spellingMenu.addItem(withTitle: title, action: Selector(selector), keyEquivalent: "")
        }
        spellingItem.submenu = spellingMenu
        editMenu.addItem(spellingItem)
        let substitutionsItem = NSMenuItem(title: "Substitutions", action: nil, keyEquivalent: "")
        let substitutionsMenu = NSMenu(title: "Substitutions")
        for (title, selector) in [("Show Substitutions", "orderFrontSubstitutionsPanel:"), ("Smart Copy/Paste", "toggleSmartInsertDelete:"), ("Smart Quotes", "toggleAutomaticQuoteSubstitution:"), ("Smart Dashes", "toggleAutomaticDashSubstitution:"), ("Smart Links", "toggleAutomaticLinkDetection:"), ("Data Detectors", "toggleAutomaticDataDetection:"), ("Text Replacement", "toggleAutomaticTextReplacement:")] {
            substitutionsMenu.addItem(withTitle: title, action: Selector(selector), keyEquivalent: "")
        }
        substitutionsItem.submenu = substitutionsMenu
        editMenu.addItem(substitutionsItem)
        let transformationsItem = NSMenuItem(title: "Transformations", action: nil, keyEquivalent: "")
        let transformationsMenu = NSMenu(title: "Transformations")
        for (title, selector) in [("Make Upper Case", "uppercaseWord:"), ("Make Lower Case", "lowercaseWord:"), ("Capitalize", "capitalizeWord:")] {
            transformationsMenu.addItem(withTitle: title, action: Selector(selector), keyEquivalent: "")
        }
        transformationsItem.submenu = transformationsMenu
        editMenu.addItem(transformationsItem)
        let speechItem = NSMenuItem(title: "Speech", action: nil, keyEquivalent: "")
        let speechMenu = NSMenu(title: "Speech")
        speechMenu.addItem(withTitle: "Start Speaking", action: Selector("startSpeaking:"), keyEquivalent: "")
        speechMenu.addItem(withTitle: "Stop Speaking", action: Selector("stopSpeaking:"), keyEquivalent: "")
        speechItem.submenu = speechMenu
        editMenu.addItem(speechItem)
        editMenu.addItem(withTitle: "Emoji & Symbols", action: #selector(NSApplication.orderFrontCharacterPalette(_:)), keyEquivalent: "")
        main.addItem(editItem)
        editItem.submenu = editMenu

        let formatItem = NSMenuItem(title: "Format", action: nil, keyEquivalent: "")
        let formatMenu = NSMenu(title: "Format")
        formatMenu.delegate = self
        formatMenu.autoenablesItems = false
        let fontItem = NSMenuItem(title: "Font", action: nil, keyEquivalent: "")
        let fontMenu = NSMenu(title: "Font")
        fontMenu.delegate = self
        let fontsItem = NSMenuItem(title: "Show Fonts", action: Selector("orderFrontFontPanel:"), keyEquivalent: "t")
        fontsItem.target = NSFontManager.shared
        fontMenu.addItem(fontsItem)
        for (title, selector, key) in [("Bold", "toggleBoldface:", "b"), ("Italic", "toggleItalics:", "i"), ("Underline", "underline:", "u")] {
            fontMenu.addItem(withTitle: title, action: Selector(selector), keyEquivalent: key)
        }
        fontMenu.addItem(withTitle: "Outline", action: #selector(NSTextView.outline(_:)), keyEquivalent: "")
        fontMenu.addItem(.separator())
        if #available(macOS 15.0, *) {
            let highlightItem = NSMenuItem(title: "Highlight", action: nil, keyEquivalent: "")
            let highlightMenu = NSMenu(title: "Highlight")
            highlightMenu.delegate = self
            let highlightColors: [(String, NSColor)] = [
                ("Accent", .controlAccentColor), ("Purple", .systemPurple), ("Pink", .systemPink),
                ("Orange", .systemOrange), ("Mint", .systemMint), ("Blue", .systemBlue)
            ]
            for (title, color) in highlightColors {
                let item = NSMenuItem(title: title, action: #selector(TextDocument.applyHighlight(_:)), keyEquivalent: "")
                item.representedObject = color
                highlightMenu.addItem(item)
            }
            highlightItem.submenu = highlightMenu
            fontMenu.addItem(highlightItem)
        }
        fontMenu.addItem(withTitle: "Styles…", action: Selector("orderFrontStylesPanel:"), keyEquivalent: "")
        for (title, tag) in [("Bigger", 3), ("Smaller", 4)] {
            let item = NSMenuItem(title: title, action: #selector(NSFontManager.modifyFont(_:)), keyEquivalent: "")
            item.target = NSFontManager.shared
            item.tag = tag
            fontMenu.addItem(item)
        }
        let kerningItem = NSMenuItem(title: "Kern", action: nil, keyEquivalent: "")
        let kerningMenu = NSMenu(title: "Kern")
        kerningMenu.delegate = self
        kerningMenu.addItem(withTitle: "Use Default", action: #selector(NSTextView.useStandardKerning(_:)), keyEquivalent: "")
        kerningMenu.addItem(withTitle: "Use None", action: #selector(NSTextView.turnOffKerning(_:)), keyEquivalent: "")
        kerningMenu.addItem(withTitle: "Tighten", action: #selector(NSTextView.tightenKerning(_:)), keyEquivalent: "")
        kerningMenu.addItem(withTitle: "Loosen", action: #selector(NSTextView.loosenKerning(_:)), keyEquivalent: "")
        kerningItem.submenu = kerningMenu
        fontMenu.addItem(kerningItem)
        let ligaturesItem = NSMenuItem(title: "Ligatures", action: nil, keyEquivalent: "")
        let ligaturesMenu = NSMenu(title: "Ligatures")
        ligaturesMenu.delegate = self
        ligaturesMenu.addItem(withTitle: "Use Default", action: #selector(NSTextView.useStandardLigatures(_:)), keyEquivalent: "")
        ligaturesMenu.addItem(withTitle: "Use None", action: #selector(NSTextView.turnOffLigatures(_:)), keyEquivalent: "")
        ligaturesMenu.addItem(withTitle: "Use All", action: #selector(NSTextView.useAllLigatures(_:)), keyEquivalent: "")
        ligaturesItem.submenu = ligaturesMenu
        fontMenu.addItem(ligaturesItem)
        let baselineItem = NSMenuItem(title: "Baseline", action: nil, keyEquivalent: "")
        let baselineMenu = NSMenu(title: "Baseline")
        baselineMenu.delegate = self
        baselineMenu.addItem(withTitle: "Use Default", action: #selector(NSText.unscript(_:)), keyEquivalent: "")
        baselineMenu.addItem(withTitle: "Superscript", action: #selector(NSText.superscript(_:)), keyEquivalent: "")
        baselineMenu.addItem(withTitle: "Subscript", action: #selector(NSText.subscript(_:)), keyEquivalent: "")
        baselineMenu.addItem(.separator())
        baselineMenu.addItem(withTitle: "Raise", action: #selector(NSTextView.raiseBaseline(_:)), keyEquivalent: "")
        baselineMenu.addItem(withTitle: "Lower", action: #selector(NSTextView.lowerBaseline(_:)), keyEquivalent: "")
        baselineItem.submenu = baselineMenu
        fontMenu.addItem(baselineItem)
        fontMenu.addItem(.separator())
        fontMenu.addItem(withTitle: "Show Colors", action: #selector(NSApplication.orderFrontColorPanel(_:)), keyEquivalent: "")
        fontMenu.addItem(withTitle: "Copy Style", action: #selector(NSText.copyFont(_:)), keyEquivalent: "")
        fontMenu.addItem(withTitle: "Paste Style", action: #selector(NSText.pasteFont(_:)), keyEquivalent: "")
        fontItem.submenu = fontMenu
        formatMenu.addItem(fontItem)

        let textItem = NSMenuItem(title: "Text", action: nil, keyEquivalent: "")
        let textMenu = NSMenu(title: "Text")
        textMenu.delegate = self
        for (title, selector) in [("Align Left", "alignLeft:"), ("Center", "alignCenter:"),
                                  ("Justify", "alignJustified:"), ("Align Right", "alignRight:")] {
            textMenu.addItem(withTitle: title, action: Selector(selector), keyEquivalent: "")
        }
        let directionItem = NSMenuItem(title: "Writing Direction", action: nil, keyEquivalent: "")
        let directionMenu = NSMenu(title: "Writing Direction")
        directionMenu.delegate = self
        let paragraphDirection = NSMenu(title: "Paragraph")
        paragraphDirection.delegate = self
        paragraphDirection.addItem(withTitle: "Default", action: #selector(NSResponder.makeBaseWritingDirectionNatural(_:)), keyEquivalent: "")
        paragraphDirection.addItem(withTitle: "Left to Right", action: #selector(NSResponder.makeBaseWritingDirectionLeftToRight(_:)), keyEquivalent: "")
        paragraphDirection.addItem(withTitle: "Right to Left", action: #selector(NSResponder.makeBaseWritingDirectionRightToLeft(_:)), keyEquivalent: "")
        let paragraphDirectionItem = NSMenuItem(title: "Paragraph", action: nil, keyEquivalent: "")
        paragraphDirectionItem.submenu = paragraphDirection
        directionMenu.addItem(paragraphDirectionItem)
        let selectionDirection = NSMenu(title: "Selection")
        selectionDirection.delegate = self
        selectionDirection.addItem(withTitle: "Default", action: #selector(NSResponder.makeTextWritingDirectionNatural(_:)), keyEquivalent: "")
        selectionDirection.addItem(withTitle: "Left to Right", action: #selector(NSResponder.makeTextWritingDirectionLeftToRight(_:)), keyEquivalent: "")
        selectionDirection.addItem(withTitle: "Right to Left", action: #selector(NSResponder.makeTextWritingDirectionRightToLeft(_:)), keyEquivalent: "")
        let selectionDirectionItem = NSMenuItem(title: "Selection", action: nil, keyEquivalent: "")
        selectionDirectionItem.submenu = selectionDirection
        directionMenu.addItem(selectionDirectionItem)
        directionItem.submenu = directionMenu
        textMenu.addItem(directionItem)
        textMenu.addItem(.separator())
        textMenu.addItem(withTitle: "Show Ruler", action: #selector(TextDocument.toggleRuler(_:)), keyEquivalent: "r")
        textMenu.addItem(withTitle: "Copy Ruler", action: #selector(NSText.copyRuler(_:)), keyEquivalent: "")
        textMenu.addItem(withTitle: "Paste Ruler", action: #selector(NSText.pasteRuler(_:)), keyEquivalent: "")
        textMenu.addItem(withTitle: "Spacing…", action: #selector(NSTextView.orderFrontSpacingPanel(_:)), keyEquivalent: "")
        textItem.submenu = textMenu
        formatMenu.addItem(textItem)

        let richPlainItem = NSMenuItem(title: "Make Plain Text", action: #selector(TextDocument.toggleRichPlainText(_:)), keyEquivalent: "t")
        richPlainItem.keyEquivalentModifierMask = [.command, .shift]
        formatMenu.addItem(richPlainItem)
        formatMenu.addItem(.separator())
        let listsItem = NSMenuItem(title: "Lists", action: nil, keyEquivalent: "")
        let listsMenu = NSMenu(title: "Lists")
        listsMenu.delegate = self
        for (title, selector) in [("Bulleted List", #selector(TextDocument.toggleBulletedList(_:))),
                                  ("Numbered List", #selector(TextDocument.toggleNumberedList(_:))),
                                  ("Remove List", #selector(TextDocument.removeList(_:)))] {
            listsMenu.addItem(withTitle: title, action: selector, keyEquivalent: "")
        }
        listsItem.submenu = listsMenu
        formatMenu.addItem(listsItem)
        formatMenu.addItem(withTitle: "Wrap to Page", action: #selector(TextDocument.togglePageWrap(_:)), keyEquivalent: "")
        formatMenu.addItem(withTitle: "Allow Hyphenation", action: #selector(TextDocument.toggleHyphenation(_:)), keyEquivalent: "")
        formatMenu.addItem(withTitle: "Prevent Editing", action: #selector(TextDocument.toggleEditingProtection(_:)), keyEquivalent: "")
        main.addItem(formatItem)
        formatItem.submenu = formatMenu

        let viewItem = NSMenuItem(title: "View", action: nil, keyEquivalent: "")
        let viewMenu = NSMenu(title: "View")
        viewMenu.addItem(withTitle: "Enter Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        viewMenu.addItem(withTitle: "Hide Toolbar", action: Selector("toggleToolbarShown:"), keyEquivalent: "")
        viewMenu.addItem(withTitle: "Customize Toolbar…", action: Selector("runToolbarCustomizationPalette:"), keyEquivalent: "")
        main.addItem(viewItem)
        viewItem.submenu = viewMenu
        let windowItem = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.zoom(_:)), keyEquivalent: "")
        windowMenu.addItem(withTitle: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
        windowItem.submenu = windowMenu
        NSApplication.shared.windowsMenu = windowMenu
        main.addItem(windowItem)
        let helpItem = NSMenuItem(title: "Help", action: nil, keyEquivalent: "")
        let helpMenu = NSMenu(title: "Help")
        helpMenu.addItem(withTitle: "FreeDEdit Help", action: Selector("showHelp:"), keyEquivalent: "?")
        helpItem.submenu = helpMenu
        main.addItem(helpItem)
        NSApplication.shared.mainMenu = main
    }

    @MainActor @objc private func showSettingsWindow(_ sender: Any?) {
        SettingsWindowController.shared.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @MainActor @objc private func newDocument(_ sender: Any?) {
        do { try createNewDocument() }
        catch { NSApp.presentError(error) }
    }

    @MainActor private func createNewDocument() throws {
        let type = (UserDefaults.standard.object(forKey: "DefaultRichText") as? Bool ?? true)
            ? UTType.rtf.identifier : UTType.plainText.identifier
        guard let document = try NSDocumentController.shared.makeUntitledDocument(ofType: type) as? TextDocument else {
            throw NSError(domain: "FreeDEdit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create a new document."])
        }
        NSDocumentController.shared.addDocument(document)
        document.makeWindowControllers()
        document.showWindows()
    }

    @MainActor @objc private func openDocument(_ sender: Any?) {
        presentOpenPanel(isLaunchPanel: false)
    }

    @MainActor private func presentLaunchOpenPanel() {
        presentOpenPanel(isLaunchPanel: true)
    }

    @MainActor private func presentOpenPanel(isLaunchPanel: Bool) {
        let panel = NSOpenPanel()
        if isLaunchPanel {
            launchOpenPanel = panel
            launchPanelRequestedNewDocument = false
            launchPanelRequestedSettings = false
        }
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = TextDocument.openableTypes
        let accessory = NSStackView()
        accessory.orientation = .vertical
        accessory.alignment = .leading
        accessory.spacing = 8
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8
        row.addArrangedSubview(NSTextField(labelWithString: "Plain Text Encoding:"))
        let encoding = NSPopUpButton(frame: .zero, pullsDown: false)
        encoding.addItems(withTitles: TextDocument.openEncodings.map(\.name))
        let preferred = UserDefaults.standard.integer(forKey: "PlainTextEncoding")
        encoding.selectItem(at: TextDocument.openEncodings.firstIndex(where: { Int($0.value) == preferred }) ?? 0)
        row.addArrangedSubview(encoding)
        let ignoreFormatting = NSButton(checkboxWithTitle: "Ignore rich text commands", target: nil, action: nil)
        ignoreFormatting.state = (UserDefaults.standard.object(forKey: "IgnoreRichText") as? Bool ?? false) ? .on : .off
        accessory.addArrangedSubview(row)
        accessory.addArrangedSubview(ignoreFormatting)
        if isLaunchPanel {
            let newDocument = NSButton(title: "New Document", target: self,
                                       action: #selector(newDocumentFromLaunchPanel(_:)))
            newDocument.bezelStyle = .rounded
            accessory.addArrangedSubview(newDocument)
            let settings = NSButton(title: "Settings…", target: self,
                                    action: #selector(settingsFromLaunchPanel(_:)))
            settings.bezelStyle = .rounded
            accessory.addArrangedSubview(settings)
        }
        accessory.frame = NSRect(x: 0, y: 0, width: 390, height: isLaunchPanel ? 112 : 62)
        panel.accessoryView = accessory
        if isLaunchPanel { panel.isAccessoryViewDisclosed = true }
        if isLaunchPanel {
            panel.begin { [weak self] response in
                guard let self else { return }
                self.launchOpenPanel = nil
                if self.launchPanelRequestedNewDocument {
                    self.launchPanelRequestedNewDocument = false
                    do { try self.createNewDocument() }
                    catch { NSApp.presentError(error) }
                    return
                }
                if self.launchPanelRequestedSettings {
                    self.launchPanelRequestedSettings = false
                    self.showSettingsWindow(nil)
                    return
                }
                self.openSelectedDocuments(from: panel, encoding: encoding,
                                           ignoreFormatting: ignoreFormatting, response: response)
            }
        } else {
            let response = panel.runModal()
            openSelectedDocuments(from: panel, encoding: encoding,
                                  ignoreFormatting: ignoreFormatting, response: response)
        }
    }

    @MainActor @objc private func newDocumentFromLaunchPanel(_ sender: Any?) {
        guard let panel = launchOpenPanel else { return }
        launchPanelRequestedNewDocument = true
        panel.cancel(nil)
    }

    @MainActor @objc private func settingsFromLaunchPanel(_ sender: Any?) {
        guard let panel = launchOpenPanel else { return }
        launchPanelRequestedSettings = true
        panel.cancel(nil)
    }

    @MainActor private func openSelectedDocuments(from panel: NSOpenPanel, encoding: NSPopUpButton,
                                                  ignoreFormatting: NSButton,
                                                  response: NSApplication.ModalResponse) {
        guard response == .OK, !panel.urls.isEmpty else { return }
        let index = encoding.indexOfSelectedItem
        let value = TextDocument.openEncodings.indices.contains(index) ? TextDocument.openEncodings[index].value : 0
        let options = TextDocument.OpenOptions(encoding: String.Encoding(rawValue: value),
                                               ignoreRichText: ignoreFormatting.state == .on)
        openDocuments(panel.urls, options: options, at: 0)
    }

    @MainActor private func openDocuments(_ urls: [URL], options: TextDocument.OpenOptions, at index: Int,
                                          completion: (() -> Void)? = nil) {
        guard urls.indices.contains(index) else { completion?(); return }
        let url = urls[index]
        TextDocument.pendingOpenOptions = options
        if url.pathExtension.lowercased() == "wordml" {
            do {
                let document = try NSDocumentController.shared.makeDocument(
                    withContentsOf: url, ofType: "com.microsoft.word.wordml")
                TextDocument.pendingOpenOptions = nil
                NSDocumentController.shared.addDocument(document)
                document.makeWindowControllers()
                document.showWindows()
            } catch {
                TextDocument.pendingOpenOptions = nil
                NSApp.presentError(error)
            }
            openDocuments(urls, options: options, at: index + 1, completion: completion)
            return
        }
        NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, error in
            TextDocument.pendingOpenOptions = nil
            if let error {
                if let recoveryOptions = self.sourceRecoveryOptions(for: url, options: options) {
                    self.openDocuments([url], options: recoveryOptions, at: 0) {
                        self.openDocuments(urls, options: options, at: index + 1, completion: completion)
                    }
                } else {
                    NSApp.presentError(error)
                    self.openDocuments(urls, options: options, at: index + 1, completion: completion)
                }
                return
            }
            self.openDocuments(urls, options: options, at: index + 1, completion: completion)
        }
    }

    @MainActor private func sourceRecoveryOptions(for url: URL, options: TextDocument.OpenOptions) -> TextDocument.OpenOptions? {
        guard !options.ignoreRichText, ["rtf", "rtfd", "html", "htm"].contains(url.pathExtension.lowercased()) else { return nil }
        let alert = NSAlert()
        alert.messageText = "Couldn’t read the document formatting"
        alert.informativeText = "FreeDEdit can try to open the document’s readable source text instead. Formatting and embedded objects may be lost."
        alert.addButton(withTitle: "Open Source Text")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        var recovery = options
        recovery.ignoreRichText = true
        return recovery
    }

    @MainActor @objc private func showFindReplace(_ sender: Any?) {
        guard let document = NSApp.keyWindow?.windowController?.document as? TextDocument else { return }
        FindReplaceWindowController.shared.show(for: document)
    }

    @MainActor @objc private func undo(_ sender: Any?) { NSApp.keyWindow?.undoManager?.undo() }
    @MainActor @objc private func redo(_ sender: Any?) { NSApp.keyWindow?.undoManager?.redo() }

    @MainActor @objc private func openRecentDocument(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, error in
            if let error { NSApp.presentError(error) }
        }
    }

    @MainActor func menuNeedsUpdate(_ menu: NSMenu) {
        if menu === recentDocumentsMenu {
            menu.removeAllItems()
            let urls = NSDocumentController.shared.recentDocumentURLs
            if urls.isEmpty {
                let item = NSMenuItem(title: "No Recent Documents", action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
            } else {
                for url in urls {
                    let item = NSMenuItem(title: url.lastPathComponent, action: #selector(openRecentDocument(_:)), keyEquivalent: "")
                    item.target = self
                    item.representedObject = url
                    menu.addItem(item)
                }
            }
            menu.addItem(.separator())
            menu.addItem(withTitle: "Clear Menu", action: #selector(NSDocumentController.clearRecentDocuments(_:)), keyEquivalent: "")
            return
        }
        guard let document = NSApp.keyWindow?.windowController?.document as? TextDocument,
              let editor = document.menuEditor else { return }
        let textViewActions: Set<String> = ["toggleBoldface:", "toggleItalics:", "underline:", "alignLeft:",
                                            "alignCenter:", "alignRight:", "alignJustified:"]
        menu.autoenablesItems = false
        for item in menu.items {
            let action = item.action.map(NSStringFromSelector) ?? ""
            switch action {
            case "undo:":
                item.title = editor.undoManager?.undoMenuItemTitle ?? "Undo"
                item.isEnabled = editor.undoManager?.canUndo ?? false
            case "redo:":
                item.title = editor.undoManager?.redoMenuItemTitle ?? "Redo"
                item.isEnabled = editor.undoManager?.canRedo ?? false
            case "cut:":
                item.isEnabled = editor.isEditable && editor.selectedRange().length > 0
            case "copy:":
                item.isEnabled = editor.selectedRange().length > 0
            case "delete:":
                item.isEnabled = editor.isEditable && editor.selectedRange().length > 0
            case "performFindPanelAction:" where item.tag == Int(NSFindPanelAction.setFindString.rawValue):
                item.isEnabled = editor.selectedRange().length > 0
            case "applyHighlight:":
                item.target = document
                item.isEnabled = editor.isRichText && editor.isEditable && editor.selectedRange().length > 0
            case "copyFont:":
                item.target = editor
                item.isEnabled = editor.isRichText && editor.selectedRange().length > 0
            case "pasteFont:":
                item.target = editor
                item.isEnabled = editor.isRichText && editor.isEditable
            case "copyRuler:":
                item.target = editor
                item.isEnabled = editor.isRichText
            case "pasteRuler:":
                item.target = editor
                item.isEnabled = editor.isRichText && editor.isEditable
            case "orderFrontSpacingPanel:":
                item.target = editor
                item.isEnabled = editor.isRichText && editor.isEditable
            case "raiseBaseline:", "lowerBaseline:":
                item.target = editor
                item.isEnabled = editor.isRichText && editor.isEditable && editor.selectedRange().length > 0
            case "outline:":
                item.target = editor
                item.isEnabled = editor.isRichText && editor.isEditable && editor.selectedRange().length > 0
            case "makeBaseWritingDirectionNatural:", "makeBaseWritingDirectionLeftToRight:", "makeBaseWritingDirectionRightToLeft:",
                 "makeTextWritingDirectionNatural:", "makeTextWritingDirectionLeftToRight:", "makeTextWritingDirectionRightToLeft:":
                item.target = editor
                item.isEnabled = editor.isRichText && editor.isEditable
            case "useStandardKerning:", "tightenKerning:", "loosenKerning:", "turnOffKerning:":
                item.target = editor
                item.isEnabled = editor.isRichText && editor.isEditable
            case "useStandardLigatures:", "useAllLigatures:", "turnOffLigatures:":
                item.target = editor
                item.isEnabled = editor.isRichText && editor.isEditable
            case "subscript:", "superscript:":
                item.target = editor
                item.isEnabled = editor.isRichText && editor.isEditable
            case "toggleRichPlainText:":
                item.isEnabled = editor.isEditable
                item.title = editor.isRichText ? "Make Plain Text" : "Make Rich Text"
            case "toggleRuler:": item.isEnabled = editor.isRichText
            case "togglePageWrap:":
                item.isEnabled = true
                item.state = (UserDefaults.standard.object(forKey: "WrapToPage") as? Bool ?? false) ? .on : .off
            case "toggleHyphenation:":
                item.target = document
                item.isEnabled = editor.isRichText && editor.isEditable
                item.state = (editor.layoutManager?.usesDefaultHyphenation ?? false) ? .on : .off
            case "toggleEditingProtection:":
                item.isEnabled = true
                item.state = editor.isEditable ? .off : .on
            case "toggleBulletedList:", "toggleNumberedList:", "removeList:", "modifyFont:":
                item.isEnabled = editor.isRichText && editor.isEditable
            case "orderFrontFontPanel:", "orderFrontColorPanel:", "orderFrontStylesPanel:":
                item.isEnabled = editor.isRichText && editor.isEditable
            default:
                if textViewActions.contains(action) {
                    item.target = editor
                    item.isEnabled = editor.isRichText && editor.isEditable
                }
            }
            if let submenu = item.submenu { submenu.delegate = self }
        }
    }

}

@MainActor
final class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()
    private var settingsScrollViews: [NSScrollView] = []

    private init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 620),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Settings"
        window.center()
        let options: [(String, String, Bool)] = [
            ("DefaultRichText", "Start new documents in rich text", true),
            ("WrapToPage", "Wrap text to page margins", false),
            ("ShowRuler", "Show the ruler in rich-text documents", true),
            ("CheckSpellingAsYouType", "Check spelling while typing", true),
            ("CheckGrammarWithSpelling", "Check grammar with spelling", false),
            ("CorrectSpellingAutomatically", "Correct spelling automatically", true),
            ("SmartQuotes", "Use smart quotes", true),
            ("SmartDashes", "Use smart dashes", true),
            ("SmartLinks", "Detect links automatically", false),
            ("TextReplacement", "Apply text replacements", true),
            ("DataDetectors", "Detect dates and other data", false),
            ("SmartCopyPaste", "Use smart copy and paste", true),
            ("SmartSubstitutionsEnabledInRichTextOnly", "Limit smart quotes and dashes to rich text", true),
            ("CheckSpellingAsYouTypeEnabledInRichTextOnly", "Limit spelling tools to rich text", false)
        ]
        let stack = NSStackView()
        var checkboxes: [NSButton] = []
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        var fontControls: [NSPopUpButton] = []
        let heading = NSTextField(labelWithString: "New Document")
        heading.font = .boldSystemFont(ofSize: 15)
        stack.addArrangedSubview(heading)
        for option in options.prefix(1) {
            let checkbox = NSButton(checkboxWithTitle: option.1, target: nil, action: nil)
            checkbox.identifier = NSUserInterfaceItemIdentifier(option.0)
            checkbox.state = (UserDefaults.standard.object(forKey: option.0) as? Bool ?? option.2) ? .on : .off
            stack.addArrangedSubview(checkbox)
            checkboxes.append(checkbox)
        }
        let metrics = NSStackView()
        metrics.orientation = .horizontal
        metrics.alignment = .centerY
        metrics.spacing = 8
        metrics.addArrangedSubview(NSTextField(labelWithString: "Plain text size:"))
        let widthField = NSTextField(string: "\(UserDefaults.standard.object(forKey: "WidthInChars") as? Int ?? 96)")
        widthField.identifier = NSUserInterfaceItemIdentifier("WidthInChars")
        widthField.widthAnchor.constraint(equalToConstant: 48).isActive = true
        metrics.addArrangedSubview(widthField)
        metrics.addArrangedSubview(NSTextField(labelWithString: "characters by"))
        let heightField = NSTextField(string: "\(UserDefaults.standard.object(forKey: "HeightInChars") as? Int ?? 30)")
        heightField.identifier = NSUserInterfaceItemIdentifier("HeightInChars")
        heightField.widthAnchor.constraint(equalToConstant: 48).isActive = true
        metrics.addArrangedSubview(heightField)
        metrics.addArrangedSubview(NSTextField(labelWithString: "lines"))
        stack.addArrangedSubview(metrics)

        let fontTitle = NSTextField(labelWithString: "Default fonts")
        fontTitle.font = .boldSystemFont(ofSize: 15)
        stack.addArrangedSubview(fontTitle)
        for (title, key, defaultName, defaultSize) in [("Plain text", "Plain", "Menlo", 11.0), ("Rich text", "Rich", "Helvetica", 12.0)] {
            let row = NSStackView()
            row.orientation = .horizontal
            row.alignment = .centerY
            row.spacing = 8
            row.addArrangedSubview(NSTextField(labelWithString: title))
            let font = NSPopUpButton(frame: .zero, pullsDown: false)
            font.identifier = NSUserInterfaceItemIdentifier("\(key)Font")
            font.addItems(withTitles: ["Menlo", "Helvetica", "Arial", "Times New Roman", "System"])
            let storedFont = UserDefaults.standard.string(forKey: "Default\(key)Font") ?? defaultName
            font.selectItem(withTitle: storedFont)
            fontControls.append(font)
            row.addArrangedSubview(font)
            let size = NSPopUpButton(frame: .zero, pullsDown: false)
            size.identifier = NSUserInterfaceItemIdentifier("\(key)Size")
            size.addItems(withTitles: (8...36).map(String.init))
            size.selectItem(withTitle: "\(UserDefaults.standard.object(forKey: "Default\(key)Size") as? Int ?? Int(defaultSize))")
            fontControls.append(size)
            row.addArrangedSubview(size)
            stack.addArrangedSubview(row)
        }

        let writing = NSTextField(labelWithString: "Writing")
        writing.font = .boldSystemFont(ofSize: 15)
        stack.addArrangedSubview(writing)
        for option in options.dropFirst() {
            let checkbox = NSButton(checkboxWithTitle: option.1, target: nil, action: nil)
            checkbox.identifier = NSUserInterfaceItemIdentifier(option.0)
            checkbox.state = (UserDefaults.standard.object(forKey: option.0) as? Bool ?? option.2) ? .on : .off
            stack.addArrangedSubview(checkbox)
            checkboxes.append(checkbox)
        }

        let openSave = NSStackView()
        openSave.orientation = .vertical
        openSave.alignment = .leading
        openSave.spacing = 14
        openSave.translatesAutoresizingMaskIntoConstraints = false
        let openSaveTitle = NSTextField(labelWithString: "Open and Save")
        openSaveTitle.font = .boldSystemFont(ofSize: 15)
        openSave.addArrangedSubview(openSaveTitle)
        var openSaveCheckboxes: [NSButton] = []
        for option in [("IgnoreRichText", "Show RTF files as source", false),
                       ("IgnoreHTML", "Show HTML files as source", false),
                       ("AddExtensionToNewPlainTextFiles", "Add .txt extension to plain-text files", true),
                       ("PreserveWhitespace", "Preserve white space when saving HTML", true),
                       ("UseTransitionalDocType", "Use transitional HTML output", false),
                       ("UseXHTMLDocType", "Use XHTML output", false)] {
            let control = NSButton(checkboxWithTitle: option.1, target: nil, action: nil)
            control.identifier = NSUserInterfaceItemIdentifier(option.0)
            control.state = (UserDefaults.standard.object(forKey: option.0) as? Bool ?? option.2) ? .on : .off
            openSave.addArrangedSubview(control)
            openSaveCheckboxes.append(control)
        }
        var encodingPopups: [NSPopUpButton] = []
        for (labelText, key) in [("Open plain-text files using:", "PlainTextEncoding"),
                                 ("Save plain-text files using:", "PlainTextEncodingForWrite")] {
            let row = NSStackView()
            row.orientation = .horizontal
            row.alignment = .centerY
            row.spacing = 8
            row.addArrangedSubview(NSTextField(labelWithString: labelText))
            let popup = NSPopUpButton(frame: .zero, pullsDown: false)
            popup.identifier = NSUserInterfaceItemIdentifier(key)
            let options = key == "PlainTextEncoding" ? TextDocument.openEncodings : TextDocument.encodings
            popup.addItems(withTitles: options.map(\.name))
            let value = UserDefaults.standard.integer(forKey: key)
            popup.selectItem(at: options.firstIndex(where: { Int($0.value) == value }) ?? 0)
            row.addArrangedSubview(popup)
            openSave.addArrangedSubview(row)
            encodingPopups.append(popup)
        }
        let htmlTitle = NSTextField(labelWithString: "HTML export")
        htmlTitle.font = .boldSystemFont(ofSize: 15)
        openSave.addArrangedSubview(htmlTitle)
        let htmlEncoding = NSStackView()
        htmlEncoding.orientation = .horizontal
        htmlEncoding.alignment = .centerY
        htmlEncoding.spacing = 8
        htmlEncoding.addArrangedSubview(NSTextField(labelWithString: "Character encoding:"))
        let htmlEncodingPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        htmlEncodingPopup.identifier = NSUserInterfaceItemIdentifier("HTMLExportEncoding")
        htmlEncodingPopup.addItem(withTitle: "Unicode (UTF-8)")
        htmlEncodingPopup.selectItem(withTitle: UserDefaults.standard.string(forKey: "HTMLExportEncoding") ?? "Unicode (UTF-8)")
        htmlEncoding.addArrangedSubview(htmlEncodingPopup)
        openSave.addArrangedSubview(htmlEncoding)
        let panePicker = NSSegmentedControl(labels: ["New Document", "Open and Save"], trackingMode: .selectOne, target: nil, action: nil)
        panePicker.selectedSegment = 0
        panePicker.translatesAutoresizingMaskIntoConstraints = false
        window.initialFirstResponder = checkboxes.first
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.documentView = stack
        scroll.translatesAutoresizingMaskIntoConstraints = false
        let openSaveScroll = NSScrollView()
        openSaveScroll.hasVerticalScroller = true
        openSaveScroll.documentView = openSave
        openSaveScroll.translatesAutoresizingMaskIntoConstraints = false
        openSaveScroll.isHidden = true
        window.contentView?.addSubview(panePicker)
        window.contentView?.addSubview(scroll)
        window.contentView?.addSubview(openSaveScroll)
        NSLayoutConstraint.activate([
            panePicker.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor, constant: 20),
            panePicker.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor, constant: -20),
            panePicker.topAnchor.constraint(equalTo: window.contentView!.topAnchor, constant: 12),
            scroll.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor, constant: 20),
            scroll.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor, constant: -20),
            scroll.topAnchor.constraint(equalTo: panePicker.bottomAnchor, constant: 10),
            scroll.bottomAnchor.constraint(equalTo: window.contentView!.bottomAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -12),
            openSaveScroll.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            openSaveScroll.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            openSaveScroll.topAnchor.constraint(equalTo: scroll.topAnchor),
            openSaveScroll.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            openSave.widthAnchor.constraint(equalTo: openSaveScroll.widthAnchor, constant: -12)
        ])
        super.init(window: window)
        settingsScrollViews = [scroll, openSaveScroll]
        window.contentView?.layoutSubtreeIfNeeded()
        scroll.layoutSubtreeIfNeeded()
        scroll.contentView.scroll(to: NSPoint(x: 0, y: max(0, stack.frame.height - scroll.contentView.bounds.height)))
        scroll.reflectScrolledClipView(scroll.contentView)
        panePicker.target = self
        panePicker.action = #selector(selectPane(_:))
        checkboxes.forEach {
            $0.target = self
            $0.action = #selector(settingChanged(_:))
        }
        widthField.target = self
        widthField.action = #selector(numberChanged(_:))
        heightField.target = self
        heightField.action = #selector(numberChanged(_:))
        fontControls.forEach {
            $0.target = self
            $0.action = #selector(fontChanged(_:))
        }
        (checkboxes + openSaveCheckboxes).forEach {
            $0.target = self
            $0.action = #selector(settingChanged(_:))
        }
        encodingPopups.forEach {
            $0.target = self
            $0.action = #selector(encodingChanged(_:))
        }
        htmlEncodingPopup.target = self
        htmlEncodingPopup.action = #selector(stringSettingChanged(_:))
    }

    required init?(coder: NSCoder) { nil }

    @objc private func settingChanged(_ sender: NSButton) {
        guard let key = sender.identifier?.rawValue else { return }
        UserDefaults.standard.set(sender.state == .on, forKey: key)
    }

    @objc private func numberChanged(_ sender: NSTextField) {
        guard let key = sender.identifier?.rawValue, let value = Int(sender.stringValue), value > 0 else { return }
        UserDefaults.standard.set(value, forKey: key)
    }

    @objc private func fontChanged(_ sender: NSPopUpButton) {
        guard let key = sender.identifier?.rawValue, let title = sender.titleOfSelectedItem else { return }
        let familyKey = key.hasSuffix("Font")
        let documentKind = key.hasPrefix("Plain") ? "Plain" : "Rich"
        UserDefaults.standard.set(familyKey ? title : Int(title) ?? 12,
                                  forKey: "Default\(documentKind)\(familyKey ? "Font" : "Size")")
    }

    @objc private func encodingChanged(_ sender: NSPopUpButton) {
        guard let key = sender.identifier?.rawValue else { return }
        let options = key == "PlainTextEncoding" ? TextDocument.openEncodings : TextDocument.encodings
        guard options.indices.contains(sender.indexOfSelectedItem) else { return }
        UserDefaults.standard.set(Int(options[sender.indexOfSelectedItem].value), forKey: key)
    }

    @objc private func stringSettingChanged(_ sender: NSPopUpButton) {
        guard let key = sender.identifier?.rawValue else { return }
        UserDefaults.standard.set(sender.titleOfSelectedItem, forKey: key)
    }

    @objc private func selectPane(_ sender: NSSegmentedControl) {
        guard settingsScrollViews.indices.contains(sender.selectedSegment) else { return }
        for (index, scroll) in settingsScrollViews.enumerated() {
            scroll.isHidden = index != sender.selectedSegment
            guard index == sender.selectedSegment else { continue }
            scroll.layoutSubtreeIfNeeded()
            let documentHeight = scroll.documentView?.frame.height ?? 0
            scroll.contentView.scroll(to: NSPoint(x: 0, y: max(0, documentHeight - scroll.contentView.bounds.height)))
            scroll.reflectScrolledClipView(scroll.contentView)
        }
    }
}

@objc(TextDocument)
final class TextDocument: NSDocument {
    private struct TextModeSnapshot {
        let contents: NSAttributedString
        let isRichText: Bool
        let showsRuler: Bool
        let selection: NSRange
    }
    private var text = NSAttributedString(string: "")
    private weak var editor: NSTextView?
    private var isPlainText = (UserDefaults.standard.object(forKey: "DefaultRichText") as? Bool) == false
    private var plainTextEncoding: String.Encoding = .utf8
    private var restorationID = UUID().uuidString
    private var restoredSelection: NSRange?
    private var restoredScrollY: CGFloat?
    var findReplaceEditor: NSTextView? { editor }
    var menuEditor: NSTextView? { editor }

    struct OpenOptions {
        var encoding: String.Encoding
        var ignoreRichText: Bool
    }
    static var pendingOpenOptions: OpenOptions?
    static let openableTypes: [UTType] = [
        .plainText, .rtf, .html,
        UTType("com.apple.rtfd")!, UTType("com.apple.webarchive")!,
        UTType("org.oasis-open.opendocument.text")!,
        UTType("org.openxmlformats.wordprocessingml.document")!,
        UTType("com.microsoft.word.wordml")!, UTType("com.microsoft.word.doc")!
    ]

    override class var autosavesInPlace: Bool { true }
    override class var preservesVersions: Bool { true }
    override class var readableTypes: [String] {
        [UTType.plainText.identifier, UTType.rtf.identifier, "com.apple.rtfd", UTType.html.identifier,
         "com.apple.webarchive", "org.oasis-open.opendocument.text",
         "org.openxmlformats.wordprocessingml.document", "com.microsoft.word.wordml", "com.microsoft.word.doc"]
    }
    override class var writableTypes: [String] { readableTypes }

    override func makeWindowControllers() {
        let plainWidth = UserDefaults.standard.object(forKey: "WidthInChars") as? Int ?? 96
        let plainHeight = UserDefaults.standard.object(forKey: "HeightInChars") as? Int ?? 30
        let windowSize = isPlainText ? NSSize(width: CGFloat(plainWidth) * 8, height: CGFloat(plainHeight) * 18) : NSSize(width: 720, height: 520)
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: windowSize),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        window.center()
        window.title = "Untitled"
        window.identifier = NSUserInterfaceItemIdentifier("FreeDEdit.DocumentWindow.\(restorationID)")
        window.setFrameAutosaveName("FreeDEdit.DocumentWindow.\(restorationID)")
        window.isRestorable = true
        window.restorationClass = NSDocumentController.self

        let scroll = NSScrollView(frame: window.contentView?.bounds ?? .zero)
        scroll.autoresizingMask = [.width, .height]
        scroll.hasVerticalScroller = true
        let wrapToPage = UserDefaults.standard.object(forKey: "WrapToPage") as? Bool ?? false
        scroll.hasHorizontalScroller = !wrapToPage
        scroll.hasHorizontalRuler = true
        scroll.borderType = .noBorder
        let storage = NSTextStorage(attributedString: text)
        let layout = NSLayoutManager()
        let container = NSTextContainer(containerSize: NSSize(width: wrapToPage ? 612 : scroll.contentView.bounds.width,
                                                               height: CGFloat.greatestFiniteMagnitude))
        container.widthTracksTextView = !wrapToPage
        container.heightTracksTextView = false
        layout.addTextContainer(container)
        storage.addLayoutManager(layout)
        let view = NSTextView(frame: scroll.contentView.bounds, textContainer: container)
        view.minSize = NSSize(width: 0, height: 0)
        view.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        view.isVerticallyResizable = true
        view.isHorizontallyResizable = !wrapToPage
        view.autoresizingMask = [.width]
        view.isRichText = !isPlainText
        view.usesFindBar = true
        view.usesFindPanel = true
        view.isIncrementalSearchingEnabled = true
        view.isEditable = true
        let showRuler = UserDefaults.standard.object(forKey: "ShowRuler") as? Bool ?? true
        view.usesRuler = !isPlainText && showRuler
        view.allowsUndo = true
        let richOnlySpelling = UserDefaults.standard.object(forKey: "CheckSpellingAsYouTypeEnabledInRichTextOnly") as? Bool ?? false
        view.isContinuousSpellCheckingEnabled = !(isPlainText && richOnlySpelling) && (UserDefaults.standard.object(forKey: "CheckSpellingAsYouType") as? Bool ?? true)
        view.isGrammarCheckingEnabled = UserDefaults.standard.object(forKey: "CheckGrammarWithSpelling") as? Bool ?? false
        view.isAutomaticSpellingCorrectionEnabled = !(isPlainText && richOnlySpelling) && (UserDefaults.standard.object(forKey: "CorrectSpellingAutomatically") as? Bool ?? true)
        let richOnlyPunctuation = UserDefaults.standard.object(forKey: "SmartSubstitutionsEnabledInRichTextOnly") as? Bool ?? true
        view.isAutomaticQuoteSubstitutionEnabled = !(isPlainText && richOnlyPunctuation) && (UserDefaults.standard.object(forKey: "SmartQuotes") as? Bool ?? true)
        view.isAutomaticDashSubstitutionEnabled = !(isPlainText && richOnlyPunctuation) && (UserDefaults.standard.object(forKey: "SmartDashes") as? Bool ?? true)
        view.isAutomaticLinkDetectionEnabled = UserDefaults.standard.object(forKey: "SmartLinks") as? Bool ?? false
        view.isAutomaticDataDetectionEnabled = UserDefaults.standard.object(forKey: "DataDetectors") as? Bool ?? false
        view.isAutomaticTextReplacementEnabled = UserDefaults.standard.object(forKey: "TextReplacement") as? Bool ?? true
        view.smartInsertDeleteEnabled = UserDefaults.standard.object(forKey: "SmartCopyPaste") as? Bool ?? true
        let documentKind = isPlainText ? "Plain" : "Rich"
        let fontName = UserDefaults.standard.string(forKey: "Default\(documentKind)Font") ?? (isPlainText ? "Menlo" : "Helvetica")
        let fontSize = CGFloat(UserDefaults.standard.object(forKey: "Default\(documentKind)Size") as? Int ?? (isPlainText ? 11 : 12))
        view.font = fontName == "System" ? NSFont.systemFont(ofSize: fontSize) : (NSFont(name: fontName, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize))
        view.textContainerInset = NSSize(width: 5, height: 8)
        view.delegate = self
        scroll.documentView = view
        window.contentView?.addSubview(scroll)
        editor = view
        let toolbar = NSToolbar(identifier: "FreeDEditFormatting")
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        toolbar.isVisible = !isPlainText
        window.toolbar = toolbar
        scroll.rulersVisible = view.usesRuler
        let controller = NSWindowController(window: window)
        addWindowController(controller)
        if let restoredSelection {
            let location = min(restoredSelection.location, view.string.utf16.count)
            let length = min(restoredSelection.length, view.string.utf16.count - location)
            view.setSelectedRange(NSRange(location: location, length: length))
        }
        if let restoredScrollY {
            scroll.contentView.scroll(to: NSPoint(x: 0, y: restoredScrollY))
            scroll.reflectScrolledClipView(scroll.contentView)
        }
        restoredSelection = nil
        restoredScrollY = nil
    }

    override func data(ofType typeName: String) throws -> Data {
        guard let editor else { return text.string.data(using: .utf8) ?? Data() }
        let range = NSRange(location: 0, length: editor.textStorage?.length ?? 0)
        if typeName == UTType.html.identifier {
            return try htmlExportData(from: editor.attributedString(), range: range)
        }
        if let documentType = attributedDocumentType(for: typeName) {
            return try editor.attributedString().data(from: range, documentAttributes: [.documentType: documentType])
        }
        guard let encoded = editor.string.data(using: plainTextEncoding, allowLossyConversion: false) else {
            let name = Self.encodings.first(where: { $0.value == plainTextEncoding.rawValue })?.name ?? "the selected encoding"
            throw NSError(domain: "FreeDEdit", code: 5,
                          userInfo: [NSLocalizedDescriptionKey: "This document contains characters that cannot be saved using \(name). Choose a different encoding and try again."])
        }
        return encoded
    }

    private func htmlExportData(from value: NSAttributedString, range: NSRange) throws -> Data {
        let encodingName = UserDefaults.standard.string(forKey: "HTMLExportEncoding") ?? "Unicode (UTF-8)"
        let encoding: String.Encoding = switch encodingName {
        case "Unicode (UTF-8)": .utf8
        case "Unicode (UTF-16)": .utf16
        case "Western (Mac OS Roman)": .macOSRoman
        default: .utf8
        }
        let attributes: [NSAttributedString.DocumentAttributeKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: Int(encoding.rawValue)
        ]
        let data = try value.data(from: range, documentAttributes: attributes)
        guard var html = String(data: data, encoding: encoding) else { return data }

        let transitional = UserDefaults.standard.object(forKey: "UseTransitionalDocType") as? Bool ?? false
        let xhtml = UserDefaults.standard.object(forKey: "UseXHTMLDocType") as? Bool ?? false
        let declaration: String
        if xhtml && transitional {
            declaration = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">"
        } else if xhtml {
            declaration = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">"
        } else if transitional {
            declaration = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">"
        } else {
            declaration = "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">"
        }
        if let range = html.range(of: #"<!DOCTYPE[^>]*>"#, options: .regularExpression) {
            html.replaceSubrange(range, with: declaration)
        }
        if xhtml {
            html = html.replacingOccurrences(of: "<html>", with: "<html xmlns=\"http://www.w3.org/1999/xhtml\">")
            for tag in ["meta", "br", "hr", "img", "link", "input"] {
                let expression = "<\(tag)(\\s[^>]*)?>"
                let replacement = "<\(tag)$1 />"
                html = html.replacingOccurrences(of: expression, with: replacement, options: .regularExpression)
            }
        }
        if UserDefaults.standard.object(forKey: "PreserveWhitespace") as? Bool ?? true {
            html = preservingTextWhitespace(in: html)
        }
        return html.data(using: encoding) ?? data
    }

    private func preservingTextWhitespace(in html: String) -> String {
        var result = ""
        var textNode = ""
        var insideTag = false

        func encodedText(_ text: String) -> String {
            let characters = Array(text)
            guard !characters.allSatisfy(\.isWhitespace) else { return text }
            var output = ""
            var index = 0
            while index < characters.count {
                let character = characters[index]
                if character == "\t" {
                    var end = index + 1
                    while end < characters.count && characters[end] == "\t" { end += 1 }
                    output += String(repeating: "&#160;", count: (end - index) * 4)
                    index = end
                    continue
                }
                guard character == " " else {
                    output.append(character)
                    index += 1
                    continue
                }
                var end = index + 1
                while end < characters.count && characters[end] == " " { end += 1 }
                let count = end - index
                let atTextEdge = index == 0 || end == characters.count
                if atTextEdge {
                    output += String(repeating: "&#160;", count: count)
                } else {
                    output += " " + String(repeating: "&#160;", count: count - 1)
                }
                index = end
            }
            return output
        }

        for character in html {
            if character == "<" && !insideTag {
                result += encodedText(textNode)
                textNode = ""
                insideTag = true
                result.append(character)
            } else if character == ">" && insideTag {
                insideTag = false
                result.append(character)
            } else if insideTag {
                result.append(character)
            } else {
                textNode.append(character)
            }
        }
        result += encodedText(textNode)
        return result
    }

    override func prepareSavePanel(_ savePanel: NSSavePanel) -> Bool {
        guard isPlainText else { return true }
        savePanel.allowedContentTypes = [.plainText]
        if UserDefaults.standard.object(forKey: "AddExtensionToNewPlainTextFiles") as? Bool ?? true,
           !savePanel.nameFieldStringValue.isEmpty,
           URL(fileURLWithPath: savePanel.nameFieldStringValue).pathExtension.isEmpty {
            savePanel.nameFieldStringValue += ".txt"
        }
        let row = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 34))
        let label = NSTextField(labelWithString: "Plain Text Encoding:")
        label.frame = NSRect(x: 0, y: 7, width: 140, height: 20)
        let popup = NSPopUpButton(frame: NSRect(x: 140, y: 3, width: 210, height: 26), pullsDown: false)
        popup.addItems(withTitles: Self.encodings.map(\.name))
        let preferred = UserDefaults.standard.integer(forKey: "PlainTextEncodingForWrite")
        let selectedEncoding = preferred == 0 ? plainTextEncoding.rawValue : UInt(preferred)
        popup.selectItem(at: Self.encodings.firstIndex(where: { $0.value == selectedEncoding }) ?? 0)
        plainTextEncoding = String.Encoding(rawValue: selectedEncoding)
        popup.target = self
        popup.action = #selector(saveEncodingChanged(_:))
        row.addSubview(label)
        row.addSubview(popup)
        savePanel.accessoryView = row
        return true
    }

    @objc private func saveEncodingChanged(_ sender: NSPopUpButton) {
        guard Self.encodings.indices.contains(sender.indexOfSelectedItem) else { return }
        let value = Self.encodings[sender.indexOfSelectedItem].value
        plainTextEncoding = String.Encoding(rawValue: value)
        UserDefaults.standard.set(Int(value), forKey: "PlainTextEncodingForWrite")
    }

    override func fileWrapper(ofType typeName: String) throws -> FileWrapper {
        guard typeName == "com.apple.rtfd" else { return try super.fileWrapper(ofType: typeName) }
        let contents = editor?.attributedString() ?? text
        return try contents.fileWrapper(from: NSRange(location: 0, length: contents.length),
                                        documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd])
    }

    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        coder.encode(restorationID as NSString, forKey: "FreeDEdit.RestorationID")
        guard let editor else { return }
        let selection = editor.selectedRange()
        coder.encode(selection.location, forKey: "FreeDEdit.SelectionLocation")
        coder.encode(selection.length, forKey: "FreeDEdit.SelectionLength")
        coder.encode(Double(editor.enclosingScrollView?.contentView.bounds.origin.y ?? 0),
                     forKey: "FreeDEdit.ScrollPositionY")
    }

    override func restoreState(with coder: NSCoder) {
        super.restoreState(with: coder)
        if let savedID = coder.decodeObject(of: NSString.self, forKey: "FreeDEdit.RestorationID") as String? {
            restorationID = savedID
        }
        guard coder.containsValue(forKey: "FreeDEdit.SelectionLocation") else { return }
        restoredSelection = NSRange(location: max(0, coder.decodeInteger(forKey: "FreeDEdit.SelectionLocation")),
                                    length: max(0, coder.decodeInteger(forKey: "FreeDEdit.SelectionLength")))
        restoredScrollY = CGFloat(coder.decodeDouble(forKey: "FreeDEdit.ScrollPositionY"))
    }

    private func printSettings() -> NSPrintInfo {
        let settings = NSPrintInfo.shared.copy() as! NSPrintInfo
        settings.horizontalPagination = .fit
        settings.verticalPagination = .automatic
        settings.isHorizontallyCentered = false
        settings.isVerticallyCentered = false
        return settings
    }

    @objc func printCurrentDocument(_ sender: Any?) {
        guard let editor else { return }
        let operation = NSPrintOperation(view: editor, printInfo: printSettings())
        operation.showsPrintPanel = true
        operation.showsProgressPanel = true
        _ = operation.run()
    }

    @objc func exportPDF(_ sender: Any?) {
        guard let editor, let textContainer = editor.textContainer else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\((displayName as String?) ?? "Untitled").pdf"
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        editor.layoutManager?.ensureLayout(for: textContainer)
        let operation = NSPrintOperation.pdfOperation(with: editor, inside: editor.bounds,
                                                       toPath: url.path, printInfo: printSettings())
        operation.showsPrintPanel = false
        operation.showsProgressPanel = true
        if !operation.run() {
            NSApp.presentError(NSError(domain: "FreeDEdit", code: 3,
                                       userInfo: [NSLocalizedDescriptionKey: "PDF export did not complete."]))
        }
    }


    @objc func makePlainText(_ sender: Any?) {
        changeTextMode(toRichText: false)
    }

    @objc func makeRichText(_ sender: Any?) {
        changeTextMode(toRichText: true)
    }

    @objc func toggleRichPlainText(_ sender: Any?) {
        guard let editor, editor.isEditable else { return }
        changeTextMode(toRichText: !editor.isRichText)
    }

    private func textModeSnapshot(from editor: NSTextView) -> TextModeSnapshot {
        let showsRuler = editor.isRichText
            ? editor.usesRuler
            : (UserDefaults.standard.object(forKey: "ShowRuler") as? Bool ?? true)
        return TextModeSnapshot(contents: NSAttributedString(attributedString: editor.attributedString()),
                                isRichText: editor.isRichText,
                                showsRuler: showsRuler,
                                selection: editor.selectedRange())
    }

    private func changeTextMode(toRichText isRichText: Bool) {
        guard let editor, editor.isEditable, editor.isRichText != isRichText else { return }
        let previous = textModeSnapshot(from: editor)
        let actionName = isRichText ? "Make Rich Text" : "Make Plain Text"
        let undoManager = editor.undoManager
        undoManager?.disableUndoRegistration()
        let rulerPreference = isRichText
            ? (previous.isRichText ? previous.showsRuler : (UserDefaults.standard.object(forKey: "ShowRuler") as? Bool ?? true))
            : false
        applyTextMode(TextModeSnapshot(contents: previous.contents, isRichText: isRichText,
                                       showsRuler: rulerPreference, selection: previous.selection), to: editor)
        undoManager?.enableUndoRegistration()
        undoManager?.registerUndo(withTarget: self) { document in
            document.restoreTextMode(previous, actionName: actionName)
        }
        undoManager?.setActionName(actionName)
        updateChangeCount(.changeDone)
    }

    private func restoreTextMode(_ snapshot: TextModeSnapshot, actionName: String) {
        guard let editor else { return }
        let current = textModeSnapshot(from: editor)
        let undoManager = editor.undoManager
        undoManager?.disableUndoRegistration()
        applyTextMode(snapshot, to: editor)
        undoManager?.enableUndoRegistration()
        undoManager?.registerUndo(withTarget: self) { document in
            document.restoreTextMode(current, actionName: actionName)
        }
        undoManager?.setActionName(actionName)
    }

    private func applyTextMode(_ snapshot: TextModeSnapshot, to editor: NSTextView) {
        editor.isRichText = snapshot.isRichText
        if snapshot.isRichText {
            editor.textStorage?.setAttributedString(snapshot.contents)
            editor.usesRuler = snapshot.showsRuler
        } else {
            editor.usesRuler = false
            editor.string = snapshot.contents.string
        }
        editor.enclosingScrollView?.rulersVisible = editor.usesRuler
        editor.window?.toolbar?.isVisible = snapshot.isRichText
        let textLength = (editor.string as NSString).length
        let location = min(snapshot.selection.location, textLength)
        let length = min(snapshot.selection.length, textLength - location)
        editor.setSelectedRange(NSRange(location: location, length: length))
        text = editor.attributedString()
        isPlainText = !snapshot.isRichText
    }

    @objc func applyHighlight(_ sender: NSMenuItem) {
        guard let editor, editor.isRichText, editor.isEditable,
              let color = sender.representedObject as? NSColor else { return }
        let highlightColor = color.withAlphaComponent(0.35)
        let range = editor.selectedRange()
        registerFormattingUndo(in: editor, range: range)
        if range.length > 0 {
            editor.textStorage?.addAttribute(.backgroundColor, value: highlightColor, range: range)
        } else {
            var attributes = editor.typingAttributes
            attributes[.backgroundColor] = highlightColor
            editor.typingAttributes = attributes
        }
        editor.didChangeText()
    }

    @objc func toggleRuler(_ sender: Any?) {
        guard let editor, editor.isRichText else { return }
        editor.usesRuler.toggle()
        editor.enclosingScrollView?.rulersVisible = editor.usesRuler
        UserDefaults.standard.set(editor.usesRuler, forKey: "ShowRuler")
    }

    @objc func togglePageWrap(_ sender: Any?) {
        guard let editor, let scroll = editor.enclosingScrollView, let container = editor.textContainer else { return }
        let enabled = !((UserDefaults.standard.object(forKey: "WrapToPage") as? Bool) ?? false)
        UserDefaults.standard.set(enabled, forKey: "WrapToPage")
        container.containerSize = NSSize(width: enabled ? 612 : scroll.contentView.bounds.width,
                                         height: CGFloat.greatestFiniteMagnitude)
        container.widthTracksTextView = !enabled
        editor.isHorizontallyResizable = !enabled
        scroll.hasHorizontalScroller = !enabled
    }

    @objc func toggleHyphenation(_ sender: Any?) {
        guard let editor, editor.isRichText, editor.isEditable,
              let layoutManager = editor.layoutManager else { return }
        setHyphenation(!layoutManager.usesDefaultHyphenation)
    }

    private func setHyphenation(_ enabled: Bool) {
        guard let editor, let layoutManager = editor.layoutManager,
              layoutManager.usesDefaultHyphenation != enabled else { return }
        let previous = layoutManager.usesDefaultHyphenation
        layoutManager.usesDefaultHyphenation = enabled
        editor.undoManager?.registerUndo(withTarget: self) { document in
            document.setHyphenation(previous)
        }
        editor.undoManager?.setActionName("Allow Hyphenation")
        updateChangeCount(.changeDone)
    }

    @objc func toggleEditingProtection(_ sender: Any?) {
        guard let editor else { return }
        editor.isEditable.toggle()
    }

    @objc func insertTable(_ sender: Any?) {
        guard let editor, editor.isRichText else { return }
        let dimensions = NSStackView()
        dimensions.orientation = .vertical
        dimensions.spacing = 8
        let rowsField = NSTextField(string: "2")
        let columnsField = NSTextField(string: "2")
        let rowsRow = NSStackView(views: [NSTextField(labelWithString: "Rows:"), rowsField])
        let columnsRow = NSStackView(views: [NSTextField(labelWithString: "Columns:"), columnsField])
        rowsRow.orientation = .horizontal
        columnsRow.orientation = .horizontal
        rowsField.widthAnchor.constraint(equalToConstant: 70).isActive = true
        columnsField.widthAnchor.constraint(equalToConstant: 70).isActive = true
        dimensions.addArrangedSubview(rowsRow)
        dimensions.addArrangedSubview(columnsRow)
        let alert = NSAlert()
        alert.messageText = "Insert Table"
        alert.informativeText = "Choose the number of rows and columns (1–20)."
        alert.accessoryView = dimensions
        alert.addButton(withTitle: "Insert")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn,
              let rowCount = Int(rowsField.stringValue), (1...20).contains(rowCount),
              let columnCount = Int(columnsField.stringValue), (1...20).contains(columnCount) else { return }
        let table = NSTextTable()
        table.numberOfColumns = columnCount
        table.layoutAlgorithm = .automatic
        table.collapsesBorders = true
        let result = NSMutableAttributedString(string: "")
        for row in 0..<rowCount {
            for column in 0..<columnCount {
                let block = NSTextTableBlock(table: table, startingRow: row, rowSpan: 1, startingColumn: column, columnSpan: 1)
                block.setWidth(0.5, type: .absoluteValueType, for: .border)
                let paragraph = NSMutableParagraphStyle()
                paragraph.textBlocks = [block]
                result.append(NSAttributedString(string: " \n", attributes: [.paragraphStyle: paragraph]))
            }
        }
        let range = editor.selectedRange()
        editor.textStorage?.replaceCharacters(in: range, with: result)
        editor.setSelectedRange(NSRange(location: range.location + result.length, length: 0))
        editor.didChangeText()
    }

    @objc func toggleBulletedList(_ sender: Any?) {
        applyList(markerFormat: .circle)
    }

    @objc func toggleNumberedList(_ sender: Any?) {
        applyList(markerFormat: .decimal)
    }

    @objc func removeList(_ sender: Any?) {
        applyList(markerFormat: nil)
    }

    private func applyList(markerFormat: NSTextList.MarkerFormat?) {
        guard let editor, editor.isRichText, let storage = editor.textStorage else { return }
        if storage.length == 0 {
            editor.insertText("\n", replacementRange: NSRange(location: 0, length: 0))
        }
        let content = editor.string as NSString
        let selection = editor.selectedRange()
        let safeStart = min(selection.location, content.length)
        let safeEnd = min(max(safeStart, NSMaxRange(selection)), content.length)
        let finalCharacter = selection.length == 0 ? safeStart : max(safeStart, safeEnd - 1)
        let start = content.paragraphRange(for: NSRange(location: safeStart, length: 0)).location
        let end = NSMaxRange(content.paragraphRange(for: NSRange(location: finalCharacter, length: 0)))
        let list = markerFormat.map { NSTextList(markerFormat: $0, options: 0) }
        var cursor = start
        while cursor < end {
            let paragraphRange = content.paragraphRange(for: NSRange(location: cursor, length: 0))
            let existing = storage.attribute(.paragraphStyle, at: cursor, effectiveRange: nil) as? NSParagraphStyle
            let style = (existing?.mutableCopy() as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
            style.textLists = list.map { [$0] } ?? []
            storage.addAttribute(.paragraphStyle, value: style, range: paragraphRange)
            cursor = NSMaxRange(paragraphRange)
        }
        editor.didChangeText()
    }

    @objc func insertAttachment(_ sender: Any?) {
        guard let editor, editor.isRichText else { return }
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        guard panel.runModal() == .OK, !panel.urls.isEmpty else { return }
        let replacement = NSMutableAttributedString(string: "")
        for url in panel.urls {
            guard let wrapper = try? FileWrapper(url: url, options: []) else { continue }
            if replacement.length > 0 { replacement.append(NSAttributedString(string: "\n")) }
            replacement.append(NSAttributedString(attachment: NSTextAttachment(fileWrapper: wrapper)))
        }
        guard replacement.length > 0 else { return }
        let range = editor.selectedRange()
        editor.insertText(replacement, replacementRange: range)
        editor.setSelectedRange(NSRange(location: range.location + replacement.length, length: 0))
        editor.didChangeText()
    }

    @objc func insertLink(_ sender: Any?) {
        guard let editor, editor.isRichText else { return }
        let range = editor.selectedRange()
        guard range.length > 0 else { NSSound.beep(); return }
        let alert = NSAlert()
        alert.messageText = "Add Link"
        let field = NSTextField(string: "https://")
        field.frame = NSRect(x: 0, y: 0, width: 280, height: 24)
        alert.accessoryView = field
        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn, let url = URL(string: field.stringValue) else { return }
        editor.textStorage?.addAttribute(.link, value: url, range: range)
        editor.textStorage?.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        editor.didChangeText()
    }

    override func read(from data: Data, ofType typeName: String) throws {
        let openOptions = Self.pendingOpenOptions
        Self.pendingOpenOptions = nil
        let showRTFSource = typeName == UTType.rtf.identifier && (openOptions?.ignoreRichText ?? (UserDefaults.standard.object(forKey: "IgnoreRichText") as? Bool ?? false))
        let showHTMLSource = typeName == UTType.html.identifier && ((UserDefaults.standard.object(forKey: "IgnoreHTML") as? Bool ?? false) || (openOptions?.ignoreRichText ?? false))
        if showRTFSource || showHTMLSource {
            let source = String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
            text = NSAttributedString(string: source)
            isPlainText = true
            plainTextEncoding = .utf8
            return
        }
        if let documentType = attributedDocumentType(for: typeName) {
            text = try NSAttributedString(data: data, options: [.documentType: documentType], documentAttributes: nil)
            isPlainText = false
        } else {
            let selected = openOptions?.encoding.rawValue ?? UInt(UserDefaults.standard.integer(forKey: "PlainTextEncoding"))
            let automatic = Self.detectPlainText(data)
            var candidates = selected == 0 ? [] : [String.Encoding(rawValue: selected)]
            if let automatic { candidates.append(automatic.1) }
            candidates.append(.macOSRoman)
            var decoded: (String, String.Encoding)?
            for encoding in candidates where decoded == nil {
                if let value = String(data: data, encoding: encoding) { decoded = (value, encoding) }
            }
            let result = decoded ?? (String(decoding: data, as: UTF8.self), .utf8)
            text = NSAttributedString(string: result.0)
            plainTextEncoding = result.1
            isPlainText = true
        }
    }

    /// Returns a conservative automatic decoding. BOMs take priority, then
    /// valid UTF-8; UTF-16/32 without BOM are only inferred from zero-byte patterns.
    private static func detectPlainText(_ data: Data) -> (String, String.Encoding)? {
        let bytes = Array(data.prefix(4))
        let bomEncodings: [([UInt8], String.Encoding)] = [
            ([0x00, 0x00, 0xFE, 0xFF], .utf32BigEndian),
            ([0xFF, 0xFE, 0x00, 0x00], .utf32LittleEndian),
            ([0xEF, 0xBB, 0xBF], .utf8),
            ([0xFE, 0xFF], .utf16BigEndian),
            ([0xFF, 0xFE], .utf16LittleEndian)
        ]
        for (bom, encoding) in bomEncodings where bytes.starts(with: bom) {
            if let decoded = String(data: data, encoding: encoding) { return (decoded, encoding) }
        }
        if let decoded = String(data: data, encoding: .utf8) { return (decoded, .utf8) }

        let raw = Array(data)
        if raw.count >= 4 {
            let evenZeros = stride(from: 0, to: raw.count, by: 2).filter { raw[$0] == 0 }.count
            let oddZeros = stride(from: 1, to: raw.count, by: 2).filter { raw[$0] == 0 }.count
            if raw.count.isMultiple(of: 4) {
                let zeroCounts = (0..<4).map { offset in
                    stride(from: offset, to: raw.count, by: 4).filter { raw[$0] == 0 }.count
                }
                if zeroCounts[0] + zeroCounts[1] + zeroCounts[2] > raw.count / 2,
                   let decoded = String(data: data, encoding: .utf32BigEndian) { return (decoded, .utf32BigEndian) }
                if zeroCounts[1] + zeroCounts[2] + zeroCounts[3] > raw.count / 2,
                   let decoded = String(data: data, encoding: .utf32LittleEndian) { return (decoded, .utf32LittleEndian) }
            }
            if oddZeros > raw.count / 5, let decoded = String(data: data, encoding: .utf16BigEndian) {
                return (decoded, .utf16BigEndian)
            }
            if evenZeros > raw.count / 5, let decoded = String(data: data, encoding: .utf16LittleEndian) {
                return (decoded, .utf16LittleEndian)
            }
        }
        return nil
    }

    override func read(from fileWrapper: FileWrapper, ofType typeName: String) throws {
        guard typeName == "com.apple.rtfd" else { return try super.read(from: fileWrapper, ofType: typeName) }
        if Self.pendingOpenOptions?.ignoreRichText == true {
            let rtfData = fileWrapper.fileWrappers?["TXT.rtf"]?.regularFileContents
                ?? fileWrapper.fileWrappers?.first(where: { $0.key.lowercased().hasSuffix(".rtf") })?.value.regularFileContents
            guard let rtfData else {
                throw NSError(domain: "FreeDEdit", code: 4,
                              userInfo: [NSLocalizedDescriptionKey: "The RTFD package contains no readable RTF source."])
            }
            text = NSAttributedString(string: String(data: rtfData, encoding: .utf8) ?? String(decoding: rtfData, as: UTF8.self))
            isPlainText = true
            plainTextEncoding = .utf8
            Self.pendingOpenOptions = nil
            return
        }
        guard let imported = try NSAttributedString(rtfdFileWrapper: fileWrapper, documentAttributes: nil) else {
            throw NSError(domain: "FreeDEdit", code: 2, userInfo: [NSLocalizedDescriptionKey: "The RTFD package could not be read."])
        }
        text = imported
        isPlainText = false
    }


    private func attributedDocumentType(for typeName: String) -> NSAttributedString.DocumentType? {
        switch typeName {
        case UTType.rtf.identifier: .rtf
        case "com.apple.rtfd": .rtfd
        case UTType.html.identifier: .html
        case "com.apple.webarchive": .webArchive
        case "com.microsoft.word.doc": .docFormat
        case "com.microsoft.word.wordml": .wordML
        case "org.openxmlformats.wordprocessingml.document": .officeOpenXML
        case "org.oasis-open.opendocument.text": .openDocument
        default: nil
        }
    }

    static let openEncodings: [(name: String, value: UInt)] = [
        ("Automatic", 0),
        ("Unicode (UTF-8)", String.Encoding.utf8.rawValue),
        ("Unicode (UTF-16)", String.Encoding.utf16.rawValue),
        ("Unicode (UTF-32)", String.Encoding.utf32.rawValue)
    ] + legacyEncodings

    private static func ianaEncoding(_ name: String) -> String.Encoding? {
        let cfEncoding = CFStringConvertIANACharSetNameToEncoding(name as CFString)
        guard cfEncoding != kCFStringEncodingInvalidId else { return nil }
        let rawValue = CFStringConvertEncodingToNSStringEncoding(cfEncoding)
        return String.Encoding(rawValue: rawValue)
    }

    private static let legacyEncodings: [(name: String, value: UInt)] = [
        ("Western (Mac OS Roman)", String.Encoding.macOSRoman.rawValue),
        ("Western (Windows Latin 1)", String.Encoding.windowsCP1252.rawValue),
        ("Western (ISO Latin 1)", String.Encoding.isoLatin1.rawValue),
        ("Central European (Windows 1250)", String.Encoding.windowsCP1250.rawValue),
        ("Cyrillic (Windows 1251)", String.Encoding.windowsCP1251.rawValue),
        ("Greek (Windows 1253)", String.Encoding.windowsCP1253.rawValue),
        ("Turkish (Windows 1254)", String.Encoding.windowsCP1254.rawValue),
        ("Hebrew (Windows 1255)", ianaEncoding("windows-1255")?.rawValue ?? 0),
        ("Arabic (Windows 1256)", ianaEncoding("windows-1256")?.rawValue ?? 0),
        ("Baltic (Windows 1257)", ianaEncoding("windows-1257")?.rawValue ?? 0),
        ("Vietnamese (Windows 1258)", ianaEncoding("windows-1258")?.rawValue ?? 0),
        ("Thai (Windows 874)", ianaEncoding("windows-874")?.rawValue ?? 0),
        ("Japanese (Shift JIS)", ianaEncoding("shift_jis")?.rawValue ?? 0),
        ("Japanese (EUC)", String.Encoding.japaneseEUC.rawValue),
        ("Japanese (ISO 2022 JP)", String.Encoding.iso2022JP.rawValue),
        ("Simplified Chinese (GBK)", ianaEncoding("gbk")?.rawValue ?? 0),
        ("Traditional Chinese (Big5)", ianaEncoding("big5")?.rawValue ?? 0),
        ("Korean (EUC KR)", ianaEncoding("euc-kr")?.rawValue ?? 0)
    ]

    static let encodings: [(name: String, value: UInt)] = [
        ("Unicode (UTF-8)", String.Encoding.utf8.rawValue),
        ("Unicode (UTF-16)", String.Encoding.utf16.rawValue),
        ("Unicode (UTF-32)", String.Encoding.utf32.rawValue)
    ] + legacyEncodings

    override func windowControllerDidLoadNib(_ windowController: NSWindowController) {
        super.windowControllerDidLoadNib(windowController)
        editor?.textStorage?.setAttributedString(text)
    }
}

@MainActor
final class FindReplaceWindowController: NSWindowController {
    static let shared = FindReplaceWindowController()

    private weak var targetDocument: TextDocument?
    private let findField = NSTextField(string: "")
    private let replaceField = NSTextField(string: "")
    private let caseSensitive = NSButton(checkboxWithTitle: "Match case", target: nil, action: nil)
    private let status = NSTextField(labelWithString: "")

    private init() {
        let window = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 440, height: 190),
                             styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Find and Replace"
        window.isReleasedWhenClosed = false
        super.init(window: window)

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        for (label, field) in [("Find:", findField), ("Replace with:", replaceField)] {
            let row = NSStackView()
            row.orientation = .horizontal
            row.alignment = .centerY
            row.spacing = 10
            let title = NSTextField(labelWithString: label)
            title.widthAnchor.constraint(equalToConstant: 100).isActive = true
            field.widthAnchor.constraint(equalToConstant: 290).isActive = true
            row.addArrangedSubview(title)
            row.addArrangedSubview(field)
            stack.addArrangedSubview(row)
        }

        let options = NSStackView(views: [caseSensitive, status])
        options.orientation = .horizontal
        options.alignment = .centerY
        options.spacing = 16
        stack.addArrangedSubview(options)

        let buttons = NSStackView()
        buttons.orientation = .horizontal
        buttons.alignment = .centerY
        buttons.spacing = 8
        for (title, action) in [("Previous", #selector(findPrevious(_:))), ("Next", #selector(findNext(_:))),
                                ("Replace", #selector(replace(_:))), ("Replace All", #selector(replaceAll(_:)))] {
            let button = NSButton(title: title, target: self, action: action)
            button.bezelStyle = .rounded
            buttons.addArrangedSubview(button)
        }
        stack.addArrangedSubview(buttons)

        window.contentView?.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: window.contentView!.trailingAnchor, constant: -18),
            stack.topAnchor.constraint(equalTo: window.contentView!.topAnchor, constant: 16)
        ])
    }

    required init?(coder: NSCoder) { nil }

    func show(for document: TextDocument) {
        self.targetDocument = document
        if let editor = document.findReplaceEditor, editor.selectedRange().length > 0 {
            findField.stringValue = (editor.string as NSString).substring(with: editor.selectedRange())
        }
        status.stringValue = ""
        showWindow(nil)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        findField.selectText(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func findNext(_ sender: Any?) { _ = find(backwards: false) }
    @objc private func findPrevious(_ sender: Any?) { _ = find(backwards: true) }

    private func find(backwards: Bool) -> NSRange? {
        guard let editor = targetDocument?.findReplaceEditor else { return nil }
        let query = findField.stringValue
        guard !query.isEmpty else { NSSound.beep(); return nil }
        let content = editor.string as NSString
        let selected = editor.selectedRange()
        let options: NSString.CompareOptions = caseSensitive.state == .on ? [] : [.caseInsensitive]
        let start = min(NSMaxRange(selected), content.length)
        let found: NSRange
        if backwards {
            let before = NSRange(location: 0, length: min(selected.location, content.length))
            let after = NSRange(location: min(selected.location, content.length),
                                length: content.length - min(selected.location, content.length))
            let first = content.range(of: query, options: options.union(.backwards), range: before)
            found = first.location != NSNotFound ? first : content.range(of: query, options: options.union(.backwards), range: after)
        } else {
            let after = NSRange(location: start, length: content.length - start)
            let before = NSRange(location: 0, length: start)
            let first = content.range(of: query, options: options, range: after)
            found = first.location != NSNotFound ? first : content.range(of: query, options: options, range: before)
        }
        guard found.location != NSNotFound else {
            status.stringValue = "Not found"
            NSSound.beep()
            return nil
        }
        editor.setSelectedRange(found)
        editor.scrollRangeToVisible(found)
        status.stringValue = ""
        return found
    }

    @objc private func replace(_ sender: Any?) {
        guard let editor = targetDocument?.findReplaceEditor else { return }
        let query = findField.stringValue
        guard !query.isEmpty else { NSSound.beep(); return }
        let selected = editor.selectedRange()
        let selectedText = (editor.string as NSString).substring(with: selected)
        let comparison: String.CompareOptions = caseSensitive.state == .on ? [] : [.caseInsensitive]
        if selected.length > 0, selectedText.compare(query, options: comparison) == .orderedSame {
            editor.insertText(replaceField.stringValue, replacementRange: selected)
            status.stringValue = "Replaced 1 occurrence"
        }
        _ = find(backwards: false)
    }

    @objc private func replaceAll(_ sender: Any?) {
        guard let editor = targetDocument?.findReplaceEditor else { return }
        let query = findField.stringValue
        guard !query.isEmpty else { NSSound.beep(); return }
        let content = editor.string as NSString
        let searchOptions: NSString.CompareOptions = caseSensitive.state == .on ? [] : [.caseInsensitive]
        var matches: [NSRange] = []
        var location = 0
        while location < content.length {
            let range = content.range(of: query, options: searchOptions,
                                      range: NSRange(location: location, length: content.length - location))
            guard range.location != NSNotFound, range.length > 0 else { break }
            matches.append(range)
            location = NSMaxRange(range)
        }
        guard !matches.isEmpty else {
            status.stringValue = "Not found"
            NSSound.beep()
            return
        }
        editor.undoManager?.beginUndoGrouping()
        for range in matches.reversed() {
            editor.insertText(replaceField.stringValue, replacementRange: range)
        }
        editor.undoManager?.endUndoGrouping()
        status.stringValue = "Replaced \(matches.count) occurrence\(matches.count == 1 ? "" : "s")"
    }
}

extension TextDocument: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        guard let editor else { return }
        text = editor.attributedString()
        updateChangeCount(.changeDone)
        invalidateRestorableState()
        updateFormattingToolbarState()
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        invalidateRestorableState()
        updateFormattingToolbarState()
    }
}

extension TextDocument: NSToolbarDelegate {
    private var toolbarIDs: [NSToolbarItem.Identifier] {
        [.init("bold"), .init("italic"), .init("underline"), .init("strike"), .flexibleSpace,
         .init("fontFamily"), .init("fontStyle"), .init("fontSize"), .init("textColor"), .init("textBackground"),
         .flexibleSpace, .init("alignment"), .init("listStyle"), .init("lineSpacing")]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarIDs
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarIDs
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        switch itemIdentifier.rawValue {
        case "bold":
            item.label = "Bold"
            item.view = formattingButton("B", tag: 1)
        case "italic":
            item.label = "Italic"
            item.view = formattingButton("I", tag: 2)
        case "underline":
            item.label = "Underline"
            item.view = formattingButton("U", tag: 3)
        case "strike":
            item.label = "Strikethrough"
            item.view = formattingButton("S", tag: 4)
        case "fontFamily":
            item.label = "Font"
            let popup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 150, height: 26), pullsDown: false)
            popup.addItems(withTitles: ["Helvetica", "Arial", "Menlo", "Monaco", "Times New Roman", "Courier New"])
            popup.target = self
            popup.action = #selector(applyFontFamily(_:))
            item.view = popup
        case "fontSize":
            item.label = "Font Size"
            let field = NSTextField(string: "12")
            field.frame = NSRect(x: 0, y: 0, width: 52, height: 25)
            field.target = self
            field.action = #selector(applyFontSize(_:))
            item.view = field
        case "fontStyle":
            item.label = "Style"
            let popup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 120, height: 26), pullsDown: false)
            popup.addItems(withTitles: ["Regular", "Bold", "Italic", "Bold Italic"])
            popup.target = self
            popup.action = #selector(applyFontStyle(_:))
            item.view = popup
        case "textColor":
            item.label = "Text Color"
            let colorWell = NSColorWell(frame: NSRect(x: 0, y: 0, width: 38, height: 25))
            colorWell.color = .black
            colorWell.target = self
            colorWell.action = #selector(applyColor(_:))
            colorWell.tag = 0
            item.view = colorWell
        case "textBackground":
            item.label = "Text Background"
            let colorWell = NSColorWell(frame: NSRect(x: 0, y: 0, width: 38, height: 25))
            colorWell.color = .clear
            colorWell.target = self
            colorWell.action = #selector(applyColor(_:))
            colorWell.tag = 1
            item.view = colorWell
        case "alignment":
            item.label = "Alignment"
            let popup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 120, height: 26), pullsDown: false)
            popup.addItems(withTitles: ["Left", "Center", "Right", "Justified"])
            popup.target = self
            popup.action = #selector(applyAlignment(_:))
            item.view = popup
        case "listStyle":
            item.label = "List Style"
            let popup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 130, height: 26), pullsDown: false)
            popup.addItems(withTitles: ["No List", "Bulleted", "Numbered"])
            popup.target = self
            popup.action = #selector(applyToolbarList(_:))
            item.view = popup
        case "lineSpacing":
            item.label = "Line Spacing"
            let popup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 130, height: 26), pullsDown: false)
            popup.addItems(withTitles: ["Single", "1.5 Lines", "Double"])
            popup.target = self
            popup.action = #selector(applyLineSpacing(_:))
            item.view = popup
        default: return nil
        }
        return item
    }

    @objc private func applyAlignment(_ sender: NSPopUpButton) {
        guard let editor, editor.isRichText else { return }
        let alignment: NSTextAlignment = switch sender.indexOfSelectedItem {
        case 1: .center
        case 2: .right
        case 3: .justified
        default: .left
        }
        let range = editor.selectedRange()
        let length = editor.textStorage?.length ?? 0
        let paragraphRange = length == 0 ? NSRange(location: 0, length: 0) :
            (editor.string as NSString).paragraphRange(for: NSRange(location: min(range.location, length), length: min(range.length, length - min(range.location, length))))
        let existing = editor.typingAttributes[.paragraphStyle] as? NSParagraphStyle ?? NSParagraphStyle.default
        let mutable = existing.mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
        mutable.alignment = alignment
        if paragraphRange.length > 0 { editor.textStorage?.addAttribute(.paragraphStyle, value: mutable, range: paragraphRange) }
        var attributes = editor.typingAttributes
        attributes[.paragraphStyle] = mutable
        editor.typingAttributes = attributes
        editor.didChangeText()
    }

    @objc private func applyToolbarList(_ sender: NSPopUpButton) {
        switch sender.indexOfSelectedItem {
        case 1: toggleBulletedList(sender)
        case 2: toggleNumberedList(sender)
        default: removeList(sender)
        }
    }

    @objc private func applyLineSpacing(_ sender: NSPopUpButton) {
        guard let editor, editor.isRichText else { return }
        let multiplier: CGFloat = switch sender.indexOfSelectedItem {
        case 1: 0.5
        case 2: 1
        default: 0
        }
        let range = editor.selectedRange()
        let length = editor.textStorage?.length ?? 0
        if length > 0 {
            let start = min(range.location, length)
            let span = range.length > 0 ? min(range.length, length - start) : 0
            let paragraphRange = (editor.string as NSString).paragraphRange(for: NSRange(location: start, length: span))
            let existing = editor.textStorage?.attribute(.paragraphStyle, at: paragraphRange.location, effectiveRange: nil) as? NSParagraphStyle
            let style = (existing?.mutableCopy() as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
            style.lineSpacing = (editor.font?.pointSize ?? 12) * multiplier
            editor.textStorage?.addAttribute(.paragraphStyle, value: style, range: paragraphRange)
            var attributes = editor.typingAttributes
            attributes[.paragraphStyle] = style
            editor.typingAttributes = attributes
        } else {
            let style = (editor.typingAttributes[.paragraphStyle] as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
            style.lineSpacing = (editor.font?.pointSize ?? 12) * multiplier
            var attributes = editor.typingAttributes
            attributes[.paragraphStyle] = style
            editor.typingAttributes = attributes
        }
        editor.didChangeText()
    }

    private func formattingButton(_ title: String, tag: Int) -> NSButton {
        let button = NSButton(title: title, target: self, action: #selector(toggleToolbarStyle(_:)))
        button.tag = tag
        button.setButtonType(.toggle)
        button.bezelStyle = .texturedRounded
        button.frame = NSRect(x: 0, y: 0, width: 34, height: 25)
        return button
    }

    private func updateFormattingToolbarState() {
        guard let editor, let toolbar = editor.window?.toolbar else { return }
        let storage = editor.textStorage
        let length = storage?.length ?? 0
        let location = length == 0 ? 0 : min(editor.selectedRange().location, length - 1)
        let attributes = length > 0 ? storage?.attributes(at: location, effectiveRange: nil) ?? [:] : editor.typingAttributes
        let font = attributes[.font] as? NSFont ?? editor.font ?? NSFont.systemFont(ofSize: 12)
        let traits = NSFontManager.shared.traits(of: font)
        for item in toolbar.items {
            switch item.itemIdentifier.rawValue {
            case "bold":
                (item.view as? NSButton)?.state = traits.contains(.boldFontMask) ? .on : .off
            case "italic":
                (item.view as? NSButton)?.state = traits.contains(.italicFontMask) ? .on : .off
            case "underline":
                let value = attributes[.underlineStyle] as? Int ?? 0
                (item.view as? NSButton)?.state = value == 0 ? .off : .on
            case "strike":
                let value = attributes[.strikethroughStyle] as? Int ?? 0
                (item.view as? NSButton)?.state = value == 0 ? .off : .on
            case "fontFamily":
                if let popup = item.view as? NSPopUpButton {
                    popup.selectItem(withTitle: font.familyName ?? font.fontName)
                }
            case "fontStyle":
                let style = traits.contains([.boldFontMask, .italicFontMask]) ? 3
                    : traits.contains(.boldFontMask) ? 1 : traits.contains(.italicFontMask) ? 2 : 0
                (item.view as? NSPopUpButton)?.selectItem(at: style)
            case "fontSize":
                (item.view as? NSTextField)?.stringValue = String(format: "%.0f", font.pointSize)
            case "textColor":
                if let color = attributes[.foregroundColor] as? NSColor { (item.view as? NSColorWell)?.color = color }
            case "textBackground":
                if let color = attributes[.backgroundColor] as? NSColor { (item.view as? NSColorWell)?.color = color }
            case "alignment":
                let style = attributes[.paragraphStyle] as? NSParagraphStyle
                let index: Int = switch style?.alignment ?? .left {
                case .center: 1
                case .right: 2
                case .justified: 3
                default: 0
                }
                (item.view as? NSPopUpButton)?.selectItem(at: index)
            case "listStyle":
                let style = attributes[.paragraphStyle] as? NSParagraphStyle
                let marker = style?.textLists.first?.markerFormat
                let index = marker == .circle ? 1 : (marker == .decimal ? 2 : 0)
                (item.view as? NSPopUpButton)?.selectItem(at: index)
            case "lineSpacing":
                let spacing = (attributes[.paragraphStyle] as? NSParagraphStyle)?.lineSpacing ?? 0
                let index = spacing >= font.pointSize * 0.75 ? 2 : (spacing > 0 ? 1 : 0)
                (item.view as? NSPopUpButton)?.selectItem(at: index)
            default:
                break
            }
        }
    }

    private func registerFormattingUndo(in editor: NSTextView, range: NSRange) {
        guard range.length > 0, let storage = editor.textStorage,
              NSMaxRange(range) <= storage.length else { return }
        let previous = NSAttributedString(attributedString: storage.attributedSubstring(from: range))
        editor.undoManager?.registerUndo(withTarget: editor) { target in
            Self.restoreFormatting(previous, in: range, editor: target)
        }
        editor.undoManager?.setActionName("Format")
    }

    private static func restoreFormatting(_ value: NSAttributedString, in range: NSRange, editor: NSTextView) {
        guard let storage = editor.textStorage, NSMaxRange(range) <= storage.length else { return }
        let current = NSAttributedString(attributedString: storage.attributedSubstring(from: range))
        editor.undoManager?.registerUndo(withTarget: editor) { target in
            Self.restoreFormatting(current, in: range, editor: target)
        }
        storage.replaceCharacters(in: range, with: value)
        editor.didChangeText()
    }

    @objc private func toggleToolbarStyle(_ sender: NSButton) {
        guard let editor else { return }
        let range = editor.selectedRange()
        let storage = editor.textStorage
        registerFormattingUndo(in: editor, range: range)
        if sender.tag == 3 || sender.tag == 4 {
            let key: NSAttributedString.Key = sender.tag == 3 ? .underlineStyle : .strikethroughStyle
            let existing = editor.typingAttributes[key] as? Int ?? 0
            let value = existing == 0 ? NSUnderlineStyle.single.rawValue : 0
            if range.length > 0 {
                let runValue = storage?.attribute(key, at: range.location, effectiveRange: nil) as? Int ?? existing
                storage?.addAttribute(key, value: runValue == 0 ? NSUnderlineStyle.single.rawValue : 0, range: range)
            }
            var attributes = editor.typingAttributes
            attributes[key] = value
            editor.typingAttributes = attributes
        } else {
            let trait = sender.tag == 1 ? NSFontTraitMask.boldFontMask : NSFontTraitMask.italicFontMask
            if range.length > 0 {
                storage?.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
                    let current = value as? NSFont ?? editor.font ?? NSFont.systemFont(ofSize: 12)
                    let traits = NSFontManager.shared.traits(of: current)
                    let desired = traits.contains(trait) ? traits.subtracting(trait) : traits.union(trait)
                    let converted = NSFontManager.shared.convert(current, toHaveTrait: desired)
                    storage?.addAttribute(.font, value: converted, range: subrange)
                }
            } else {
                var attributes = editor.typingAttributes
                let current = attributes[.font] as? NSFont ?? editor.font ?? NSFont.systemFont(ofSize: 12)
                let traits = NSFontManager.shared.traits(of: current)
                let desired = traits.contains(trait) ? traits.subtracting(trait) : traits.union(trait)
                attributes[.font] = NSFontManager.shared.convert(current, toHaveTrait: desired)
                editor.typingAttributes = attributes
            }
        }
        editor.didChangeText()
        updateFormattingToolbarState()
    }

    @objc private func applyFontSize(_ sender: NSTextField) {
        guard let editor, let size = Double(sender.stringValue), size > 0 else { return }
        let font = editor.font ?? NSFont.systemFont(ofSize: size)
        let sizedFont = NSFont(descriptor: font.fontDescriptor, size: size) ?? NSFont.systemFont(ofSize: size)
        let range = editor.selectedRange()
        registerFormattingUndo(in: editor, range: range)
        if range.length > 0 {
            editor.textStorage?.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
                let existing = value as? NSFont ?? font
                let resized = NSFont(descriptor: existing.fontDescriptor, size: size) ?? sizedFont
                editor.textStorage?.addAttribute(.font, value: resized, range: subrange)
            }
        } else {
            var attributes = editor.typingAttributes
            attributes[.font] = sizedFont
            editor.typingAttributes = attributes
        }
        editor.didChangeText()
    }

    @objc private func applyFontFamily(_ sender: NSPopUpButton) {
        guard let editor, let family = sender.titleOfSelectedItem else { return }
        let range = editor.selectedRange()
        registerFormattingUndo(in: editor, range: range)
        let currentFont = editor.font ?? NSFont.systemFont(ofSize: 12)
        let converted = NSFontManager.shared.convert(currentFont, toFamily: family)
        if range.length > 0 { editor.textStorage?.addAttribute(.font, value: converted, range: range) }
        else {
            var attributes = editor.typingAttributes
            attributes[.font] = converted
            editor.typingAttributes = attributes
        }
        editor.didChangeText()
    }

    @objc private func applyFontStyle(_ sender: NSPopUpButton) {
        guard let editor else { return }
        let font = editor.font ?? NSFont.systemFont(ofSize: 12)
        let traits: NSFontTraitMask = switch sender.indexOfSelectedItem {
        case 1: .boldFontMask
        case 2: .italicFontMask
        case 3: [.boldFontMask, .italicFontMask]
        default: []
        }
        let converted = NSFontManager.shared.convert(font, toHaveTrait: traits)
        let range = editor.selectedRange()
        registerFormattingUndo(in: editor, range: range)
        if range.length > 0 { editor.textStorage?.addAttribute(.font, value: converted, range: range) }
        else {
            var attributes = editor.typingAttributes
            attributes[.font] = converted
            editor.typingAttributes = attributes
        }
        editor.didChangeText()
    }

    @objc private func applyColor(_ sender: NSColorWell) {
        guard let editor else { return }
        let key: NSAttributedString.Key = sender.tag == 0 ? .foregroundColor : .backgroundColor
        let range = editor.selectedRange()
        registerFormattingUndo(in: editor, range: range)
        if range.length > 0 { editor.textStorage?.addAttribute(key, value: sender.color, range: range) }
        else {
            var attributes = editor.typingAttributes
            attributes[key] = sender.color
            editor.typingAttributes = attributes
        }
        editor.didChangeText()
    }
}
