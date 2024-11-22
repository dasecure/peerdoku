import Foundation

/// Represents different difficulty levels for Sudoku puzzles
enum SudokuDifficulty {
    case easy
    case medium
    case hard
    case expert
    
    /// Number of cells to remove for each difficulty level
    /// The range ensures some variability in puzzle generation
    var cellsToRemove: ClosedRange<Int> {
        switch self {
        case .easy:    return 35...40  // Leaves 41-46 numbers (Beginner friendly)
        case .medium:  return 45...50  // Leaves 31-36 numbers (Moderate challenge)
        case .hard:    return 52...57  // Leaves 24-29 numbers (Advanced players)
        case .expert:  return 59...64  // Leaves 17-22 numbers (Maximum difficulty)
        }
    }
}

/// Handles the generation of Sudoku puzzles with varying difficulties
struct SudokuGenerator {
    
    // MARK: - Public Interface
    
    /// Generates a new Sudoku puzzle with its solution
    /// - Parameter difficulty: The desired difficulty level (defaults to easy)
    /// - Returns: A tuple containing the puzzle and its solution
    static func generatePuzzle(difficulty: SudokuDifficulty = .easy) -> (puzzle: [[Int]], solution: [[Int]]) {
        let solution = generateSolution()
        let puzzle = createPuzzleFromSolution(solution, difficulty: difficulty)
        return (puzzle, solution)
    }
    
    // MARK: - Private Methods
    
    /// Generates a complete, valid Sudoku solution
    private static func generateSolution() -> [[Int]] {
        var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        _ = fillGrid(&grid)
        return grid
    }
    
    /// Recursively fills the grid with valid numbers
    /// Uses backtracking algorithm to ensure a valid solution
    private static func fillGrid(_ grid: inout [[Int]]) -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                if grid[row][col] == 0 {
                    // Try numbers in random order to generate different solutions
                    let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9].shuffled()
                    for num in numbers {
                        if isValid(grid, row, col, num) {
                            grid[row][col] = num
                            if fillGrid(&grid) {
                                return true
                            }
                            grid[row][col] = 0
                        }
                    }
                    return false
                }
            }
        }
        return true
    }
    
    /// Checks if a number can be placed in a given position
    /// - Parameters:
    ///   - grid: The current Sudoku grid
    ///   - row: Target row
    ///   - col: Target column
    ///   - num: Number to validate
    /// - Returns: True if the number can be placed at the position
    private static func isValid(_ grid: [[Int]], _ row: Int, _ col: Int, _ num: Int) -> Bool {
        // Check row
        for x in 0..<9 {
            if grid[row][x] == num {
                return false
            }
        }
        
        // Check column
        for x in 0..<9 {
            if grid[x][col] == num {
                return false
            }
        }
        
        // Check 3x3 box
        let startRow = row - row % 3
        let startCol = col - col % 3
        for i in 0..<3 {
            for j in 0..<3 {
                if grid[i + startRow][j + startCol] == num {
                    return false
                }
            }
        }
        
        return true
    }
    
    /// Creates a puzzle by removing numbers from a complete solution
    /// - Parameters:
    ///   - solution: The complete Sudoku solution
    ///   - difficulty: The desired difficulty level
    /// - Returns: A puzzle with appropriate number of cells removed
    private static func createPuzzleFromSolution(_ solution: [[Int]], difficulty: SudokuDifficulty) -> [[Int]] {
        var puzzle = solution
        
        // Create list of all positions and shuffle them
        let positions = (0..<9).flatMap { row in
            (0..<9).map { col in (row, col) }
        }.shuffled()
        
        // Remove random cells based on difficulty
        let cellsToRemove = Int.random(in: difficulty.cellsToRemove)
        for i in 0..<cellsToRemove {
            let (row, col) = positions[i]
            puzzle[row][col] = 0
        }
        
        return puzzle
    }
}