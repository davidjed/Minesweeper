//
//  Minesweeper.swift
//  Minesweeper
//
//  Created by David Jedeikin on 7/3/20.
//  Copyright © 2020 David Jedeikin. All rights reserved.
//

import Foundation

public class Minesweeper {

    let consoleIO = ConsoleIO()
    var model: MinesweeperModel?
    
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
                let newArgs = self.numericComponents(input)
                if newArgs.count == 2 {
                    self.model = MinesweeperModel(dimension: newArgs[0], bombs: newArgs[1])
                    consoleIO.writeMessage("*** NEW GAME ***")
                    consoleIO.writeMessage(self.currentBoard())
                }
                else {
                    consoleIO.writeMessage("Invalid entry; please create new game with 'new x y' for a new game of dimension x, bombs y.")
                }
            }
            else if input.hasPrefix("reveal") {
                let newArgs = self.numericComponents(input)
                if let currentModel = self.model, newArgs.count == 2 {
                    if newArgs[0] >= currentModel.dimension || newArgs[1] >= currentModel.dimension {
                        consoleIO.writeMessage("Invalid entry; please reveal cells within the board's dimensions.")
                    }
                    else {
                        let revealed = self.reveal(column: newArgs[0], row: newArgs[1])
                        consoleIO.writeMessage(revealed)
                    }
                }
                else {
                    consoleIO.writeMessage("Invalid entry; please create new game with 'new x y' for a new game of dimension x, bombs y.")
                }
            }
            //TEST ONLY
            else if input == "board" {
                consoleIO.writeMessage(self.currentBoard())
            }
            else {
                consoleIO.writeMessage("Invalid entry: \(input)")
            }
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
    
    func reveal(column: Int, row: Int) -> String {
        guard let currentModel = self.model else { return "No current game" }
        guard let currentNode = currentModel.nodeAt(column: column, row: row) else { return "" }
        
        if currentNode.hasBomb {
            let result = "*** BOOM! YOU LOST! ***\n \(self.currentBoard())"
            self.model = nil
            return result
        }
        else {
            let revealedNodes = currentModel.reveal(column: column, row: row)

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
