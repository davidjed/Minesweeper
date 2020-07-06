//
//  ConsoleIO.swift
//  Minesweeper
//
//  Created by David Jedeikin on 7/3/20.
//  Copyright © 2020 David Jedeikin. All rights reserved.
//

import Foundation

class ConsoleIO {
    func writeMessage(_ message: String) {
        print("\(message)")
    }
    
    func getInput() -> String {
        let keyboard = FileHandle.standardInput
        let inputData = keyboard.availableData
        let strData = String(data: inputData, encoding: String.Encoding.utf8)!

        return strData.trimmingCharacters(in: CharacterSet.newlines)
    }
}
