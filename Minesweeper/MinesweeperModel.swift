//
//  MinesweeperModel.swift
//  Minesweeper
//
//  Created by David Jedeikin on 7/4/20.
//  Copyright © 2020 David Jedeikin. All rights reserved.
//

import Foundation

public class MinesweeperModel {
    
    var dimension: Int
    var nodes: [MinesweeperNode] = []
    var edges: [MinesweeperEdge] = []
    
    init(dimension: Int, bombs: Int) {
        self.dimension = dimension
        
        //unique set of random numbers for bombs
        var bombCells = Set<Coord>()
        while bombCells.count < bombs {
            let randomColumn = Int.random(in: 0..<dimension)
            let randomRow = Int.random(in: 0..<dimension)
            let bombCell = Coord(column: randomColumn, row: randomRow)
            
            if !bombCells.contains(bombCell) {
                bombCells.update(with: bombCell)
            }
        }
        
        //build node
        for nodeIndex in 0..<(dimension*dimension) {
            let row = Int(floor(Double(nodeIndex/dimension)))
            let column = nodeIndex % dimension
            
//            print("col: \(column), row: \(row)")
            
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
    
    func reveal(column: Int, row: Int) -> [MinesweeperNode] {
        guard let node = self.nodeAt(column: column, row: row) else { return [] }
        return node.reveal()
    }
    
    func revealAll() {
        for node in self.nodes {
            node.hidden = false
        }
    }
}

struct Coord: Hashable {
  let column: Int
  let row: Int
}

public class MinesweeperNode {
    
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
            return "+"
        }
        else if self.hasBomb  {//!self.hidden && self.hasBomb  {
            return "*"
        }
        else if !self.hidden {
            let bombs = self.neighborBombs()
            return bombs > 0 ? String(bombs) : "O"
        }
        //default hidden state
        else {
            return " "
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
    func reveal(_ recursive: Bool = false) -> [MinesweeperNode] {
        var nodes: [MinesweeperNode] = []
        
        //always includes self if not recursive
        if !recursive {
            self.hidden = false
            nodes.append(self)
        }
        
        //return only self if has bomb
        if self.hasBomb {
            return nodes
        }
        else {
            for neighbor in neighbors {
                //skip neighbors with bombs
                if neighbor.hasBomb {
                    continue
                }
                else {
                    neighbor.hidden = false
                    nodes.append(neighbor)
                    
                    //recurse thru all valid neighbor nodes if this node has no neighborBombs
                    if self.neighborBombs() == 0 {
                        nodes.append(contentsOf: neighbor.reveal(true))
                    }
                }
            }
        }
        
        return nodes
    }
}

public class MinesweeperEdge {
    
    var origin: MinesweeperNode
    var destination: MinesweeperNode
    
    init(origin: MinesweeperNode, destination: MinesweeperNode) {
        self.origin = origin
        self.destination = destination
    }
    
}
