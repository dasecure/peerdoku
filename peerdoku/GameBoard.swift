import SpriteKit

/// Manages the visual representation and layout of the Sudoku game board
class GameBoard {
    // MARK: - Constants
    
    /// Grid layout constants
    private struct Constants {
        static let size = 9
        static let cellSize: CGFloat = 40
        static let gridLineWidth: CGFloat = 2
    }
    
    // MARK: - Properties
    
    /// 2D array of cell nodes representing the game board
    private(set) var cells: [[SKShapeNode]] = []
    
    /// 2D array of number labels within cells
    private(set) var numbers: [[SKLabelNode]] = []
    
    /// Current theme for visual styling
    private let theme: Theme
    
    // MARK: - Initialization
    
    /// Initializes a new game board within the provided scene
    /// - Parameters:
    ///   - scene: The SpriteKit scene to add the board to
    ///   - theme: The theme to apply to the board
    init(scene: SKScene, theme: Theme) {
        self.theme = theme
        createGrid(in: scene)
    }
    
    // MARK: - Grid Creation
    
    private func createGrid(in scene: SKScene) {
        let gridWidth = CGFloat(Constants.size) * Constants.cellSize
        let startX = (scene.size.width - gridWidth) / 2
        let startY = (scene.size.height - gridWidth) / 2
        
        createCellsAndNumbers(startX: startX, startY: startY, in: scene)
        createGridLines(startX: startX, startY: startY, gridWidth: gridWidth, in: scene)
    }
    
    private func createCellsAndNumbers(startX: CGFloat, startY: CGFloat, in scene: SKScene) {
        for row in 0..<Constants.size {
            var cellRow: [SKShapeNode] = []
            var numberRow: [SKLabelNode] = []
            
            for col in 0..<Constants.size {
                let cell = createCell(row: row, col: col, startX: startX, startY: startY)
                let number = createNumber(at: cell.position)
                
                scene.addChild(cell)
                scene.addChild(number)
                
                cellRow.append(cell)
                numberRow.append(number)
            }
            cells.append(cellRow)
            numbers.append(numberRow)
        }
    }
    
    private func createCell(row: Int, col: Int, startX: CGFloat, startY: CGFloat) -> SKShapeNode {
        let cell = SKShapeNode(rectOf: CGSize(width: Constants.cellSize, height: Constants.cellSize))
        cell.position = CGPoint(
            x: startX + CGFloat(col) * Constants.cellSize + Constants.cellSize/2,
            y: startY + CGFloat(row) * Constants.cellSize + Constants.cellSize/2
        )
        cell.strokeColor = theme.outlineColor
        cell.lineWidth = 1
        cell.name = "cell_\(row)_\(col)"
        cell.fillColor = theme.cellColor
        return cell
    }
    
    private func createNumber(at position: CGPoint) -> SKLabelNode {
        let number = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        number.fontSize = 24
        number.fontColor = theme.textColor
        number.position = position
        number.verticalAlignmentMode = .center
        return number
    }
    
    private func createGridLines(startX: CGFloat, startY: CGFloat, gridWidth: CGFloat, in scene: SKScene) {
        for i in 0...3 {
            let boldLine = SKShapeNode()
            let path = CGMutablePath()
            
            path.move(to: CGPoint(x: startX + CGFloat(i * 3) * Constants.cellSize, y: startY))
            path.addLine(to: CGPoint(x: startX + CGFloat(i * 3) * Constants.cellSize, y: startY + gridWidth))
            
            path.move(to: CGPoint(x: startX, y: startY + CGFloat(i * 3) * Constants.cellSize))
            path.addLine(to: CGPoint(x: startX + gridWidth, y: startY + CGFloat(i * 3) * Constants.cellSize))
            
            boldLine.path = path
            boldLine.strokeColor = theme.outlineColor
            boldLine.lineWidth = Constants.gridLineWidth
            scene.addChild(boldLine)
        }
    }
    
    // MARK: - Board State Management
    
    func fillBoard(with puzzle: [[Int]]) {
        for row in 0..<Constants.size {
            for col in 0..<Constants.size {
                if puzzle[row][col] != 0 {
                    numbers[row][col].text = "\(puzzle[row][col])"
                    numbers[row][col].fontColor = theme.initialNumberColor
                } else {
                    numbers[row][col].text = ""
                }
                cells[row][col].fillColor = theme.cellColor
                cells[row][col].strokeColor = theme.outlineColor
            }
        }
    }
    
    func clearBoard() {
        for row in 0..<Constants.size {
            for col in 0..<Constants.size {
                numbers[row][col].text = ""
                cells[row][col].fillColor = theme.cellColor
                cells[row][col].strokeColor = theme.outlineColor
            }
        }
    }
}
