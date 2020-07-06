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
            consoleIO.writeMessage("Type 'new x y' for a new game with columns x, rows y.\nType 'reveal x y' to reveal grid cell at column x, row y.\nType 'q' to quit.")
            let input = consoleIO.getInput()
         
            if input == "q" {
                shouldQuit = true
            }
            //TODO parse for size and bomb count
            else if input.hasPrefix("new") {
                self.model = MinesweeperModel(dimension: 10, bombs: 5)
            }
            else {
                consoleIO.writeMessage("You entered: \(input)")
            }
        }
    }
}
