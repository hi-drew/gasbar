//
//  main.swift
//  gasbar
//
//  Created by Andrew Fagin on 7/2/23.
//

import Cocoa
// 1
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// 2
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)

