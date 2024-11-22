import Foundation

class GameState {
    var currentDifficulty: SudokuDifficulty = .easy
    var mistakes = 0
    var selectedCell: (row: Int, col: Int)?
    var currentBoard: [[Int]] = []
    var solution: [[Int]] = []
    var elapsedTime: TimeInterval = 0
    
    func resetGame() {
        mistakes = 0
        selectedCell = nil
        elapsedTime = 0
        let (puzzle, sol) = SudokuGenerator.generatePuzzle(difficulty: currentDifficulty)
        currentBoard = puzzle
        solution = sol
    }
    
    func isCorrectNumber(_ number: Int, at cell: (row: Int, col: Int)) -> Bool {
        return number == solution[cell.row][cell.col]
    }
} 