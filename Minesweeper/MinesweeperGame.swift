//
//  Minesweeper.swift
//  Minesweeper
//
//  Created by David Jedeikin on 7/3/20.
//  Copyright © 2020 David Jedeikin. All rights reserved.
//

import Foundation

//move to main.swift file if running from Xcode
_ = Minesweeper()

class Minesweeper {

    let consoleIO = ConsoleIO()
    var model: MinesweeperModel?
    
    static let noGameError = "Invalid entry; please create new game first."
    static let wrongDimensionsError = "Invalid entry; please enter two digits."
    static let promptMessage = "Type 'new x y' for a new game of dimension x, bombs y.\nType 'reveal x y' to reveal grid cell at column x, row y.\nType 'q' to quit."
    static let wonMessage = "*** YOU WON!!! ***"

    init() {
        consoleIO.writeMessage("Welcome to Minesweeper.")

        var shouldQuit = false
        while !shouldQuit {
            consoleIO.writeMessage(Minesweeper.promptMessage)
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
                    //check if won
                    if self.hasWon() {
                        consoleIO.writeMessage(Minesweeper.wonMessage)
                        self.model = nil
                    }
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
                    //check if won
                    if self.hasWon() {
                        consoleIO.writeMessage(Minesweeper.wonMessage)
                        self.model = nil
                    }
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
                if !currentModel.isStarted() {
                    board += MinesweeperNode.hiddenCell
                }
                else if let node = currentModel.nodeAt(column: column, row: row) {
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
        
        let revealedNodes = currentModel.reveal(column: column, row: row)
        if revealedNodes.count == 1 && revealedNodes[0].hasBomb {
            currentModel.revealAll()
            let result = "*** BOOM! YOU LOST! ***\n \(self.currentBoard())"
            self.model = nil
            return result
        }
        else {
            _ = currentModel.reveal(column: column, row: row)

            //return entire board as it's more readable than just subset of nodes
            return self.currentBoard()
        }
    }
    
    func hasWon() -> Bool {
        guard let currentModel = self.model else { return false }
        
        return currentModel.hasWon()
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

//convenience class
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

class MinesweeperModel {
    
    var dimension: Int
    var bombCount: Int
    var nodes: [MinesweeperNode] = []
    
    //initializes a new game but doesn't start it until the first mark or reveal action is called
    init(dimension: Int, bombs: Int) {
        self.dimension = dimension
        self.bombCount = bombs
    }
    
    func isStarted() -> Bool {
        return self.nodes.count > 0
    }
    
    //starts game using existing dimensions and bombCount
    //excludes coords passed in from having a bomb
    private func start(column: Int, row: Int) {
        //unique set of random numbers for bombs
        var bombCells = Set<Coord>()
        while bombCells.count < self.bombCount {
            let randomColumn = Int.random(in: 0..<dimension)
            let randomRow = Int.random(in: 0..<dimension)
            
            //skip specified cell
            if randomColumn == column && randomRow == row {
                continue
            }
            
            let bombCell = Coord(column: randomColumn, row: randomRow)
            
            bombCells.insert(bombCell)
        }
        
        //build node
        for nodeIndex in 0..<(dimension*dimension) {
            let row = Int(floor(Double(nodeIndex/dimension)))
            let column = nodeIndex % dimension
            let cell = MinesweeperNode(column: column, row: row)

            //check if randomly-generated bombCell matches current cell
            let bombCellMatch = Coord(column: column, row: row)
            if bombCells.contains(bombCellMatch) {
                cell.hasBomb = true
            }

            self.nodes.append(cell)
        }
        
        //build neighbors
        //a neighbor is a cell adjacent to another cell in any direction
        //if cell's column or row is 0, no neighbors before it
        //if cell's column or row is dimension-1 (0-index) no neighbors after it
        //build an array of coords to represent this
        let neighborDeltas: [Coord] = [Coord(column: -1, row: -1), Coord(column: 0, row: -1), Coord(column: 1, row: -1),
                                       Coord(column: -1, row: 0), Coord(column: 1, row: 0),
                                       Coord(column: -1, row: 1), Coord(column: 0, row: 1), Coord(column: 1, row: 1)]
        for node in self.nodes {
            let column = node.column
            let row = node.row
            
            for neighborDelta in neighborDeltas {
                let neighborColumn = column + neighborDelta.column
                let neighborRow = row + neighborDelta.row
                
                //skip invalids
                if neighborColumn < 0 || neighborRow < 0 || neighborColumn >= self.dimension || neighborRow >= self.dimension {
                    continue
                }
                
                if let neighbor = self.nodeAt(column: neighborColumn, row: neighborRow) {
                    node.neighbors.append(neighbor)
                }
            }
        }
    }
    
    func nodeAt(column: Int, row: Int) -> MinesweeperNode? {
        if column >= dimension || row >= dimension {
            return nil
        }
        
        let index = column + row * self.dimension
        
        return self.nodes[index]
    }
    
    func mark(column: Int, row: Int) {
        if !self.isStarted() {
            self.start(column: column, row: row)
        }
        if let node = self.nodeAt(column: column, row: row), node.hidden {
            node.marked = !node.marked
        }
    }

    func reveal(column: Int, row: Int) -> [MinesweeperNode] {
        if !self.isStarted() {
            self.start(column: column, row: row)
        }
        guard let node = self.nodeAt(column: column, row: row) else { return [] }
        var revealedNodes: [MinesweeperNode] = []
        revealedNodes.append(contentsOf: node.reveal())
        return revealedNodes
    }
    
    func revealAll() {
        for node in self.nodes {
            node.hidden = false
        }
    }
    
    func hasWon() -> Bool {
        var won = true
        
        //if not started, not won
        if !self.isStarted() {
            return false
        }
        for node in self.nodes {
            //a hidden marked node with a mine counts as a win
            //a revealed node with no mine counts as a win
            won = node.hidden && node.marked && node.hasBomb || !node.hidden && !node.hasBomb
            
            if !won {
                break
            }
        }

        return won
    }
}

//convenience struct
struct Coord: Hashable {
  let column: Int
  let row: Int
}

//represents a single cell in the game
class MinesweeperNode : Hashable, Equatable {
    
    static let hiddenCell = " "
    static let revealedCell = "O"
    static let bombCell = "*"
    static let markedCell = "+"

    var column: Int
    var row: Int
    var hasBomb: Bool = false
    var hidden: Bool = true
    var marked: Bool = false
    var neighbors: Array<MinesweeperNode>

    init(column: Int, row: Int) {
        self.column = column
        self.row = row
        self.neighbors = Array<MinesweeperNode>()
    }
    
    func description() -> String {
        if self.marked {
            return MinesweeperNode.markedCell
        }
        else if !self.hidden && self.hasBomb {
            return MinesweeperNode.bombCell
        }
        else if !self.hidden {
            let bombs = self.neighborBombs()
            return bombs > 0 ? String(bombs) : MinesweeperNode.revealedCell
        }
        //default hidden state
        else {
            return MinesweeperNode.hiddenCell
        }
    }
    
    //returns count of neighbor bombs
    func neighborBombs() -> Int {
        var bombs = 0
        for neighbor in self.neighbors {
            bombs += (neighbor.hasBomb ? 1 : 0)
        }
        
        return bombs
    }
    
    //if this node contains bomb, reveal itself
    //if not, recursively reveal all non-bomb and bomb-adjacent nodes
    func reveal(_ currentNodes: Set<MinesweeperNode> = []) -> Set<MinesweeperNode> {
        var nodes: Set<MinesweeperNode> = []
        currentNodes.forEach { nodes.insert($0) }
        
        //always unhide start node
        if currentNodes.count == 0 {
            self.hidden = false
            //return only self if has bomb
            if self.hasBomb {
                nodes.insert(self)
                return nodes
            }
        }
        //only add neighbor nodes and recursions of it if doesn't contain a bomb
        else if !self.hasBomb {
            self.hidden = false
            nodes.insert(self)
        }
        
        //recurse thru all valid neighbor nodes only if this node has no neighborBombs
        if self.neighborBombs() == 0 {
            for neighbor in self.neighbors {
                //if already revealed, no need to recurse
                if !neighbor.hidden {
                    continue
                }
                let revealedNeighbors = neighbor.reveal(nodes)
                revealedNeighbors.forEach { nodes.insert($0) }
            }
        }
        
        return nodes
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.column)
        hasher.combine(self.row)
    }
    
    public static func ==(lhs: MinesweeperNode, rhs: MinesweeperNode) -> Bool {
        return lhs.row == rhs.row && lhs.column == rhs.column
    }
}
