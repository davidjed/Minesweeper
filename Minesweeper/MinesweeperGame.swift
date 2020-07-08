//
//  Minesweeper.swift
//  Minesweeper
//
//  Created by David Jedeikin on 7/3/20.
//  Copyright © 2020 David Jedeikin. All rights reserved.
//

import Foundation

class Minesweeper {

    let consoleIO = ConsoleIO()
    var model: MinesweeperModel?
    
    static let noGameError = "Invalid entry; please create new game first."
    static let wrongDimensionsError = "Invalid entry; please enter two digits."

    static func main() {
        _ = Minesweeper()
    }

    init() {
        consoleIO.writeMessage("Welcome to Minesweeper.")

        var shouldQuit = false
        while !shouldQuit {
            consoleIO.writeMessage("Type 'new x y' for a new game of dimension x, bombs y.\nType 'reveal x y' to reveal grid cell at column x, row y.\nType 'q' to quit.")
            let input = consoleIO.getInput()
         
            if input == "q" {
                shouldQuit = true
            }
            else if input.hasPrefix("new") {
                let validation = self.validate(input: input, action: "mark")
                let newArgs = self.numericComponents(input)
                if validation == "" {
                    self.model = MinesweeperModel(dimension: newArgs[0], bombs: newArgs[1])
                    consoleIO.writeMessage("*** NEW GAME ***")
                    consoleIO.writeMessage(self.currentBoard())
                }
                else {
                    consoleIO.writeMessage(validation)
                }
            }
            else if input.hasPrefix("mark") {
                let markArgs = self.numericComponents(input)
                let validation = self.validate(input: input, action: "mark")
                if validation == "" {
                    let marked = self.mark(column: markArgs[0], row: markArgs[1])
                    consoleIO.writeMessage(marked)
                }
                else {
                    consoleIO.writeMessage(validation)
                }
            }
            else if input.hasPrefix("reveal") {
                let revealArgs = self.numericComponents(input)
                let validation = self.validate(input: input, action: "mark")
                if validation == "" {
                    let revealed = self.reveal(column: revealArgs[0], row: revealArgs[1])
                    consoleIO.writeMessage(revealed)
                }
                else {
                    consoleIO.writeMessage(validation)
                }
            }
            else {
                consoleIO.writeMessage("Invalid entry: \(input)")
            }
        }
    }
    
    //validates input for game actions; if valid input, returns empty string
    func validate(input: String, action: String) -> String {
        let numericArgs = self.numericComponents(input)
        if input.hasPrefix("new") {
            return numericArgs.count == 2 ? "" : Minesweeper.wrongDimensionsError
        }
        else if let currentModel = self.model, numericArgs.count == 2 {
            if numericArgs[0] < 0 || numericArgs[0] >= currentModel.dimension ||
               numericArgs[1] < 0 || numericArgs[1] >= currentModel.dimension {
                return "Invalid entry; please \(action) cells within the board's dimensions."
            }
            else {
                return ""
            }
        }
        else if numericArgs.count != 2 {
            return Minesweeper.wrongDimensionsError
        }
        else {
            return Minesweeper.noGameError
        }
    }
        
    func currentBoard() -> String {
        guard let currentModel = self.model else { return "No current game" }
        //print rows-wise, since Strings are built as rows of text
        var board: String = ""
        for _ in 0..<((currentModel.dimension * 2) + 1) {
            board += "-"
        }
        board += "\n"
        for row in 0..<currentModel.dimension {
            board += "|"
            for column in 0..<currentModel.dimension {
                if let node = currentModel.nodeAt(column: column, row: row) {
                    board += node.description()
                }
                
                //column separators
                board += "|"
            }
            
            //row separator
            board += "\n"
            for _ in 0..<((currentModel.dimension * 2) + 1) {
                board += "-"
            }
            board += "\n"
        }
        
        return board
    }
    
    func mark(column: Int, row: Int) -> String {
        guard let currentModel = self.model else { return "No current game" }
        
        currentModel.mark(column: column, row: row)

        return self.currentBoard()
    }
    
    func reveal(column: Int, row: Int) -> String {
        guard let currentModel = self.model else { return "No current game" }
        guard let currentNode = currentModel.nodeAt(column: column, row: row) else { return "" }
        
        if currentNode.hasBomb {
            currentModel.revealAll()
            let result = "*** BOOM! YOU LOST! ***\n \(self.currentBoard())"
            self.model = nil
            return result
        }
        else {
            _ = currentModel.reveal(column: column, row: row)

            //TODO return subset of nodes
            return self.currentBoard()
        }
    }
    
    //returns numeric portion of whitespace-separated string with three elements
    //first element is ignored
    //if string is not in this form, returns empty array
    private func numericComponents(_ input: String) -> [Int] {
        var numerics: [Int] = []
        
        let newArgs = input.components(separatedBy: " ")
        if newArgs.count == 3, let first = Int(newArgs[1]), let second = Int(newArgs[2]) {
            numerics.append(first)
            numerics.append(second)
        }
        
        return numerics
    }
}
