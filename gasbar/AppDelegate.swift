//  AppDelegate.swift
//  gasbar
//
//  Created by Andrew Fagin on 7/2/23.

import Cocoa
import SwiftSoup

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var lastRefreshItem: NSMenuItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "fuelpump.fill", accessibilityDescription: "Gas")
            if let gasValue = button.title.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) {
                let tooltipText = "\(gasValue) gwei"
                button.toolTip = tooltipText
                button.title = tooltipText
            } else {
                let tooltipText = "- gwei"
                button.toolTip = tooltipText
                button.title = tooltipText
            }
        }
        // Scrape and update gas price
        scrapeAndUpdateGasPrice()

        // Schedule hourly updates
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            self.scrapeAndUpdateGasPrice()
        }
        setupMenus()
    }

    func setupMenus() {
        let menu = NSMenu()

        // Display last refresh time
        lastRefreshItem = NSMenuItem(title: "Last Refresh: Never", action: nil, keyEquivalent: "")
        menu.addItem(lastRefreshItem)

        // Add a separator
        menu.addItem(NSMenuItem.separator())

        // Refresh gas price item
        let refreshItem = NSMenuItem(title: "Refresh Gas Price", action: #selector(refreshGasPrice(_:)), keyEquivalent: "r")
        menu.addItem(refreshItem)

        // Add a separator
        menu.addItem(NSMenuItem.separator())

        // Quit item
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc func refreshGasPrice(_ sender: NSMenuItem) {
        scrapeAndUpdateGasPrice()
        updateLastRefreshTime()
    }
    
    func updateLastRefreshTime() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let currentTime = dateFormatter.string(from: Date())
        
        DispatchQueue.main.async {
            if let menu = self.statusItem.menu {
                self.lastRefreshItem.title = "Last Refresh: \(currentTime)"
                menu.update()
            }
        }
    }

    func scrapeAndUpdateGasPrice() {
        guard let url = URL(string: "https://etherscan.io/gastracker") else {
            print("Invalid URL")
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            if let error = error {
                print("Error: \(error)")
                return
            }

            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                print("Invalid data")
                return
            }

            do {
                let doc = try SwiftSoup.parse(html)

                guard let gasPriceElement = try doc.select("#spanAvgPrice").first() else {
                    print("Gas price element not found")
                    return
                }

                let gasPrice = try gasPriceElement.text()
                print(gasPrice)

                DispatchQueue.main.async {
                    if let button = self?.statusItem.button {
                        let tooltipText = "\(gasPrice) gwei"
                        button.toolTip = tooltipText
                        button.title = tooltipText
                    }
                }
            } catch {
                print("Error: \(error)")
            }
        }
        task.resume()
        updateLastRefreshTime()
    }
}

