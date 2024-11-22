//
//  GameScene.swift
//  peerdoku
//
//  Created by Vincent Ooi on 11/20/24.
//

import SpriteKit

// Grid layout constants
private struct GridConstants {
    static let size = 9
    static let cellSize: CGFloat = 40
    static let lineWidth: CGFloat = 2
}

/// A SpriteKit scene that manages the main Sudoku game interface.
/// Handles game board rendering, user interaction, and game state management.
class GameScene: SKScene {
    // MARK: - Constants
    
    /// Number pad constants
    private struct NumberPadConstants {
        static let height: CGFloat = 50
        static let buttonWidth: CGFloat = 35
        static let spacing: CGFloat = 5
    }
    
    // Convenience properties for accessing constants
    private var gridSize: Int { GridConstants.size }
    private var cellSize: CGFloat { GridConstants.cellSize }
    private var gridLineWidth: CGFloat { GridConstants.lineWidth }
    
    // MARK: - UI Properties
    
    /// Grid-related properties
    private var cells: [[SKShapeNode]] = []
    private var numbers: [[SKLabelNode]] = []
    private var selectedCell: (row: Int, col: Int)? = nil
    private var containerBox: SKShapeNode?
    
    /// Game state indicators
    private var mistakes = 0
    private var mistakeNodes: [SKNode] = []
    private var gameOverNode: SKNode?
    private var modalOverlay: SKShapeNode?
    
    /// Timer-related properties
    private var timerLabel: SKLabelNode?
    private var elapsedTime: TimeInterval = 0
    private var lastUpdateTime: TimeInterval?
    private var timerIsRunning = false
    
    /// UI Controls
    private var newGameButton: SKShapeNode?
    private var difficultyButtons: [SKShapeNode] = []
    private var difficultyTitleLabel: SKLabelNode?
    private var backButton: SKShapeNode?
    private var settingsButton: SKShapeNode?
    private var resumeButton: SKShapeNode?
    
    // MARK: - Game State Properties
    
    private var currentBoard: [[Int]] = []
    private var currentSolution: [[Int]] = []
    private var currentDifficulty: SudokuDifficulty = .easy
    private var isGamePaused: Bool = false
    private var currentTheme: Theme = .dark
    
    private var initialBoard: [[Int]] { currentBoard }
    private var solution: [[Int]] { currentSolution }
    
    /// Structure to track game performance
    private struct GameScore {
        let difficulty: SudokuDifficulty
        let mistakes: Int
        let completionTime: TimeInterval
        let isPerfect: Bool
    }
    
    private var gameScores: [GameScore] = []
    
    // MARK: - Lifecycle
    
    override func didMove(to view: SKView) {
        // Apply theme before creating any UI elements
        applyTheme()
        
        // Create empty board first
        createGrid()
        createNumberPad()
        createMistakeIndicators()
        createTimer()
        createBackButton()
        createSettingsButton()
        
        // Show difficulty selection immediately
        showDifficultySelection()
    }
    
    // MARK: - Grid Creation
    
    private func createGrid() {
        let gameBoard = GameBoard(scene: self, theme: currentTheme)
        cells = gameBoard.cells
        numbers = gameBoard.numbers
    }
    
    // MARK: - Number Pad Creation
    
    private func createNumberPad() {
        let startY = (size.height - CGFloat(gridSize) * cellSize) / 4
        _ = NumberPad(scene: self, yPosition: startY, theme: currentTheme)
    }
    
    // MARK: - Mistake Indicators
    
    private func createMistakeIndicators() {
        let startX = (size.width - NumberPadConstants.buttonWidth * 3) / 2
        let startY = (size.height - CGFloat(gridSize) * cellSize) / 4 - 40
        
        // Create exactly 3 indicators
        mistakeNodes = []  // Clear any existing nodes
        
        for i in 0..<3 {
            let indicator = SKShapeNode(circleOfRadius: 5)
            indicator.position = CGPoint(x: startX + CGFloat(i) * 15, y: startY)
            indicator.fillColor = currentTheme.cellColor
            indicator.strokeColor = currentTheme.outlineColor
            indicator.lineWidth = 1
            mistakeNodes.append(indicator)
            addChild(indicator)
        }
    }
    
    // MARK: - Timer
    
    private func createTimer() {
        let label = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        label.fontSize = 32
        label.fontColor = currentTheme.timerColor
        label.text = "00:00"
        
        // Calculate position relative to the grid
        let gridWidth = CGFloat(gridSize) * cellSize
        let startY = (size.height + gridWidth) / 2 + 40
        
        label.position = CGPoint(
            x: size.width/2,
            y: startY
        )
        label.verticalAlignmentMode = .center
        
        timerLabel = label
        addChild(label)
    }
    
    // MARK: - Game Logic
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            let name = node.name ?? node.parent?.name
            
            if let nodeName = name {
                // Handle back button first
                if nodeName == "back_button" {
                    clearAllContainers()
                    showDifficultySelection(showResume: true)
                    return
                }
                
                if nodeName == "settings_button" {
                    clearAllContainers()
                    showSettings()
                    return
                } else if nodeName == "toggle_theme" {
                    toggleTheme()
                    clearAllContainers()
                    showSettings()
                    return
                } else if nodeName == "close_settings" {
                    clearAllContainers()
                    return
                }
                
                if modalOverlay != nil {
                    switch nodeName {
                    case "resume_game":
                        clearAllContainers()
                        startTimer()
                        isGamePaused = false
                        return
                    case "show_leaderboard":
                        GameCenterManager.shared.showLeaderboard()
                    case "continue", "perfect_continue":
                        clearAllContainers()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                            self?.showDifficultySelection()
                        }
                        return
                    case _ where nodeName.starts(with: "difficulty_"):
                        let difficultyStr = String(nodeName.split(separator: "_")[1])
                        switch difficultyStr {
                        case "easy":   currentDifficulty = .easy
                        case "medium": currentDifficulty = .medium
                        case "hard":   currentDifficulty = .hard
                        case "expert": currentDifficulty = .expert
                        default: break
                        }
                        resetGame()
                        return
                    default:
                        break
                    }
                } else if nodeName.starts(with: "cell_") {
                    handleCellTouch(name: nodeName)
                } else if nodeName.starts(with: "button_") {
                    handleNumberPadTouch(name: nodeName)
                }
            }
        }
    }
    
    // MARK: - Cell Touch Handling
    
    private func handleCellTouch(name: String) {
        let components = name.split(separator: "_")
        if components.count == 3,
           let row = Int(components[1]),
           let col = Int(components[2]) {
            // Clear all previous highlighting and animations
            clearAllHighlights()
            
            // Get the number in the tapped cell
            let cellNumber: String?
            if initialBoard[row][col] != 0 {
                cellNumber = "\(initialBoard[row][col])"
            } else {
                cellNumber = numbers[row][col].text
            }
            
            // If there's a number in the cell, highlight all matching numbers
            if let number = cellNumber, !number.isEmpty {
                highlightAllMatchingNumbers(number)
            }
            
            // If it's an empty or player-entered cell, show selection highlight
            if initialBoard[row][col] == 0 {
                cells[row][col].fillColor = currentTheme.selectedCellColor
                cells[row][col].lineWidth = 3
                cells[row][col].strokeColor = currentTheme.selectedCellColor.withAlphaComponent(0.8)
                
                // Add pulsing animation for empty cell
                let pulseAction = SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.4, duration: 0.5),
                    SKAction.fadeAlpha(to: 0.8, duration: 0.5)
                ])
                let repeatPulse = SKAction.repeatForever(pulseAction)
                cells[row][col].run(repeatPulse, withKey: "pulseAnimation")
                
                // Add a subtle scale animation
                let scaleAction = SKAction.sequence([
                    SKAction.scale(to: 1.05, duration: 0.5),
                    SKAction.scale(to: 1.0, duration: 0.5)
                ])
                let repeatScale = SKAction.repeatForever(scaleAction)
                cells[row][col].run(repeatScale, withKey: "scaleAnimation")
                
                selectedCell = (row, col)
            } else {
                selectedCell = nil
            }
        }
    }
    
    // MARK: - Number Pad Touch Handling
    
    private func handleNumberPadTouch(name: String) {
        print("Number pad touched: \(name)")
        
        guard let cell = selectedCell else {
            print("No cell selected")
            return
        }
        
        // Don't allow modifying initial numbers
        if initialBoard[cell.row][cell.col] != 0 {
            print("Cannot modify initial number")
            return
        }
        
        let numberStr = String(name.split(separator: "_")[1])
        guard let number = Int(numberStr) else {
            print("Failed to parse number from: \(name)")
            return
        }
        
        print("Attempting to place \(number) at cell [\(cell.row), \(cell.col)]")
        print("Expected number at this position: \(solution[cell.row][cell.col])")
        
        if number == solution[cell.row][cell.col] {
            print("✅ Correct answer")
            numbers[cell.row][cell.col].text = numberStr
            numbers[cell.row][cell.col].fontColor = currentTheme.initialNumberColor
            
            // Show brief green flash
            cells[cell.row][cell.col].fillColor = currentTheme.correctNumberColor.withAlphaComponent(0.3)
            
            // Reset and highlight matching numbers after flash
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard let self = self else { return }
                self.highlightAllMatchingNumbers(numberStr)
                
                // Make the current cell more prominent
                self.cells[cell.row][cell.col].fillColor = SKColor.yellow.withAlphaComponent(0.6)
                // self.currentTheme.matchingNumbersColor
                self.cells[cell.row][cell.col].alpha = 1.0
            }
            
            // Check if this number is now completed
            checkAndRemoveCompletedNumber(numberStr)
            
            checkForWin()
        } else {
            print("❌ Wrong answer")
            showWrongAnswer(at: cell)
            addMistake()
            self.selectedCell = nil
        }
    }
    
    // MARK: - Game Over
    
    private func showWrongAnswer(at cell: (row: Int, col: Int)) {
        cells[cell.row][cell.col].fillColor = currentTheme.wrongNumberColor.withAlphaComponent(0.8)
        
        // Update mistake indicator
        if mistakes < mistakeNodes.count {
            if let indicator = mistakeNodes[mistakes] as? SKShapeNode {
                indicator.fillColor = currentTheme.errorColor
            }
        }
    }
    
    private func addMistake() {
        // Make sure we don't exceed array bounds
        if mistakes >= 3 || mistakes >= mistakeNodes.count {
            gameOver()
            return
        }
        
        // Safely access the mistake indicator
        if let indicator = mistakeNodes[mistakes] as? SKShapeNode {
            indicator.fillColor = currentTheme.errorColor
            mistakes += 1
            
            if mistakes >= 3 {
                gameOver()
            }
        }
    }
    
    private func gameOver() {
        stopTimer()
        selectedCell = nil
        
        // Update modal overlay
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        overlay.position = CGPoint(x: size.width/2, y: size.height/2)
        overlay.fillColor = currentTheme.modalOverlayColor
        overlay.strokeColor = .clear
        modalOverlay = overlay
        addChild(overlay)
        
        // Update container
        let container = SKShapeNode(rectOf: CGSize(width: 300, height: 250))
        container.position = CGPoint(x: size.width/2, y: size.height/2)
        container.fillColor = currentTheme.containerColor
        container.strokeColor = currentTheme.containerStrokeColor
        container.lineWidth = 2
        container.zPosition = 1
        containerBox = container
        addChild(container)
        
        // Show game over message
        let gameOverLabel = SKLabelNode(text: "Game Over!")
        gameOverLabel.fontSize = 36
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: size.width/2, y: size.height/2 + 80)
        gameOverLabel.zPosition = 2
        gameOverNode = gameOverLabel
        addChild(gameOverLabel)
        
        // Add leaderboard button
        let leaderboardButton = SKShapeNode(rectOf: CGSize(width: 150, height: 40))
        leaderboardButton.fillColor = .systemBlue
        leaderboardButton.strokeColor = .black
        leaderboardButton.lineWidth = 2
        leaderboardButton.position = CGPoint(x: size.width/2, y: size.height/2)
        leaderboardButton.zPosition = 2
        leaderboardButton.name = "show_leaderboard"
        
        let leaderboardLabel = SKLabelNode(text: "Leaderboard")
        leaderboardLabel.fontSize = 20
        leaderboardLabel.fontColor = .white
        leaderboardLabel.verticalAlignmentMode = .center
        leaderboardButton.addChild(leaderboardLabel)
        addChild(leaderboardButton)
        
        // Add continue button
        let continueButton = SKShapeNode(rectOf: CGSize(width: 150, height: 40))
        continueButton.fillColor = .green
        continueButton.strokeColor = .black
        continueButton.lineWidth = 2
        continueButton.position = CGPoint(x: size.width/2, y: size.height/2 - 60)
        continueButton.zPosition = 2
        continueButton.name = "continue"
        
        let continueLabel = SKLabelNode(text: "Continue")
        continueLabel.fontSize = 20
        continueLabel.fontColor = .black
        continueLabel.verticalAlignmentMode = .center
        continueButton.addChild(continueLabel)
        addChild(continueButton)
    }
    
    // MARK: - Difficulty Selection
    
    private func showDifficultySelection(showResume: Bool = false) {
        // Update modal overlay
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        overlay.position = CGPoint(x: size.width/2, y: size.height/2)
        overlay.fillColor = currentTheme.modalOverlayColor
        overlay.strokeColor = .clear
        overlay.zPosition = 1
        modalOverlay = overlay
        addChild(overlay)
        
        // Update container
        let container = SKShapeNode(rectOf: CGSize(width: 300, height: showResume ? 350 : 300))
        container.position = CGPoint(x: size.width/2, y: size.height/2)
        container.fillColor = currentTheme.containerColor
        container.strokeColor = currentTheme.containerStrokeColor
        container.lineWidth = 2
        container.zPosition = 2
        containerBox = container
        addChild(container)
        
        // Update difficulty buttons
        let difficulties: [(difficulty: SudokuDifficulty, title: String, color: SKColor)] = [
            (.easy, "Easy", currentTheme.easyButtonColor),
            (.medium, "Medium", currentTheme.mediumButtonColor),
            (.hard, "Hard", currentTheme.hardButtonColor),
            (.expert, "Expert", currentTheme.expertButtonColor)
        ]
        
        difficultyButtons.removeAll()
        
        for (index, difficulty) in difficulties.enumerated() {
            let button = SKShapeNode(rectOf: CGSize(width: 150, height: 40))
            button.fillColor = difficulty.color
            button.strokeColor = .black
            button.lineWidth = 2
            button.position = CGPoint(
                x: size.width/2,
                y: size.height/2 + 40 - CGFloat(index * 45)
            )
            button.zPosition = 3
            button.name = "difficulty_\(difficulty.title.lowercased())"
            
            let label = SKLabelNode(text: difficulty.title)
            label.fontSize = 20
            label.fontColor = .black
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            button.addChild(label)
            
            addChild(button)
            difficultyButtons.append(button)
        }
        
        // Add resume button if game is paused
        if showResume {
            let resumeButton = SKShapeNode(rectOf: CGSize(width: 150, height: 40))
            resumeButton.fillColor = .systemBlue
            resumeButton.strokeColor = .black
            resumeButton.lineWidth = 2
            resumeButton.position = CGPoint(
                x: size.width/2,
                y: size.height/2 - 140
            )
            resumeButton.zPosition = 3
            resumeButton.name = "resume_game"
            
            let resumeLabel = SKLabelNode(text: "Resume Game")
            resumeLabel.fontSize = 20
            resumeLabel.fontColor = .white
            resumeLabel.verticalAlignmentMode = .center
            resumeButton.addChild(resumeLabel)
            
            self.resumeButton = resumeButton
            addChild(resumeButton)
        }
        
        // Stop timer if game is being paused
        if showResume {
            stopTimer()
            isGamePaused = true
        }
    }
    
    // MARK: - Game Reset
    
    private func resetGame() {
        // Generate new puzzle
        generateNewPuzzle()
        
        // Start fresh game
        clearAllHighlights()
        mistakes = 0
        
        // Clear and refill board with new puzzle
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                // Clear all cell formatting
                cells[row][col].removeAction(forKey: "pulseAnimation")
                cells[row][col].removeAction(forKey: "scaleAnimation")
                cells[row][col].alpha = 1.0
                cells[row][col].setScale(1.0)
                cells[row][col].fillColor = currentTheme.cellColor
                cells[row][col].strokeColor = currentTheme.outlineColor
                cells[row][col].lineWidth = 1
                
                // Set new numbers
                numbers[row][col].text = initialBoard[row][col] == 0 ? "" : "\(initialBoard[row][col])"
                numbers[row][col].fontColor = initialBoard[row][col] == 0 ? 
                    currentTheme.textColor : currentTheme.initialNumberColor
            }
        }
        
        // Reset mistakes indicators
        for node in mistakeNodes {
            if let indicator = node as? SKShapeNode {
                indicator.fillColor = currentTheme.cellColor
            }
        }
        
        // Clear all UI elements
        clearAllContainers()
        
        // Clear selection
        selectedCell = nil
        
        // Start fresh timer
        startTimer()
    }
    
    // MARK: - Perfect Game Congratulations
    
    private func showPerfectGameCongratulations() {
        stopTimer()
        
        // Create modal overlay with theme colors
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        overlay.position = CGPoint(x: size.width/2, y: size.height/2)
        overlay.fillColor = currentTheme.modalOverlayColor
        overlay.strokeColor = .clear
        overlay.zPosition = 1
        modalOverlay = overlay
        addChild(overlay)
        
        // Create congratulations container with theme colors
        let container = SKShapeNode(rectOf: CGSize(width: 300, height: 250))
        container.fillColor = currentTheme.containerColor
        container.strokeColor = currentTheme.containerStrokeColor
        container.lineWidth = 2
        container.position = CGPoint(x: size.width/2, y: size.height/2)
        container.zPosition = 2
        containerBox = container
        addChild(container)
        
        // Perfect game title with theme colors
        let perfectLabel = SKLabelNode(text: "🌟 PERFECT! 🌟")
        perfectLabel.fontSize = 36
        perfectLabel.fontColor = currentTheme.correctNumberColor
        perfectLabel.position = CGPoint(x: size.width/2, y: size.height/2 + 80)
        perfectLabel.zPosition = 3
        addChild(perfectLabel)
        
        // Game details with theme colors
        let detailsLabel = SKLabelNode(text: "\(currentDifficulty)".capitalized)
        detailsLabel.fontSize = 28
        detailsLabel.fontColor = currentTheme.textColor
        detailsLabel.position = CGPoint(x: size.width/2, y: size.height/2 + 20)
        detailsLabel.zPosition = 3
        addChild(detailsLabel)
        
        let timeLabel = SKLabelNode(text: "Time: \(formatTime(elapsedTime))")
        timeLabel.fontSize = 28
        timeLabel.fontColor = currentTheme.textColor
        timeLabel.position = CGPoint(x: size.width/2, y: size.height/2 - 20)
        timeLabel.zPosition = 3
        addChild(timeLabel)
        
        // Continue button with theme colors
        let continueButton = SKShapeNode(rectOf: CGSize(width: 150, height: 40))
        continueButton.fillColor = currentTheme.buttonColor
        continueButton.strokeColor = currentTheme.buttonStrokeColor
        continueButton.lineWidth = 2
        continueButton.position = CGPoint(x: size.width/2, y: size.height/2 - 80)
        continueButton.zPosition = 3
        continueButton.name = "perfect_continue"
        
        let continueLabel = SKLabelNode(text: "Continue")
        continueLabel.fontSize = 24
        continueLabel.fontColor = currentTheme.buttonTextColor
        continueLabel.verticalAlignmentMode = .center
        continueButton.addChild(continueLabel)
        addChild(continueButton)
    }
    
    // MARK: - Game Over Check
    
    private func checkForWin() {
        // Check if all cells are filled correctly
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if numbers[row][col].text != "\(solution[row][col])" {
                    return
                }
            }
        }
        
        // Submit score to Game Center
        let score = GameCenterManager.shared.calculateScore(
            difficulty: currentDifficulty,
            time: elapsedTime,
            mistakes: mistakes
        )
        GameCenterManager.shared.submitScore(score, difficulty: currentDifficulty)
        
        // Record the score
        let currentScore = GameScore(
            difficulty: currentDifficulty,
            mistakes: mistakes,
            completionTime: elapsedTime,
            isPerfect: mistakes == 0
        )
        gameScores.append(currentScore)
        
        if mistakes == 0 {
            // Show perfect game congratulations
            showPerfectGameCongratulations()
        } else {
            // Show regular game over
            gameOver()
        }
    }
    
    // MARK: - Game Statistics
    
    private func getGameStats() -> String {
        guard !gameScores.isEmpty else { return "No games played yet" }
        
        var stats = "Game History:\n"
        for (index, score) in gameScores.reversed().prefix(5).enumerated() {
            stats += "\(index + 1). \(score.difficulty)".capitalized
            stats += " - Time: \(formatTime(score.completionTime))"
            stats += " - Mistakes: \(score.mistakes)"
            if score.isPerfect {
                stats += " ⭐️"
            }
            stats += "\n"
        }
        
        return stats
    }
    
    // MARK: - Puzzle Generation
    
    private func generateNewPuzzle() {
        let (puzzle, solution) = SudokuGenerator.generatePuzzle(difficulty: currentDifficulty)
        currentBoard = puzzle
        currentSolution = solution
    }
    
    // MARK: - Timer Control
    
    private func startTimer() {
        timerIsRunning = true
        lastUpdateTime = nil
        elapsedTime = 0
        timerLabel?.text = "00:00"
    }
    
    private func stopTimer() {
        timerIsRunning = false
        lastUpdateTime = nil
    }
    
    // MARK: - Update
    
    override func update(_ currentTime: TimeInterval) {
        guard timerIsRunning else { return }
        
        if let lastUpdate = lastUpdateTime {
            let delta = currentTime - lastUpdate
            elapsedTime += delta
            timerLabel?.text = formatTime(elapsedTime)
        }
        
        lastUpdateTime = currentTime
    }
    
    // MARK: - Time Formatting
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Back Button
    
    private func createBackButton() {
        let button = SKShapeNode(rectOf: CGSize(width: 60, height: 40))
        button.position = CGPoint(x: 50, y: size.height - 40)
        button.fillColor = currentTheme.buttonColor
        button.strokeColor = currentTheme.buttonStrokeColor
        button.lineWidth = 1
        button.name = "back_button"
        
        let label = SKLabelNode(text: "Back")
        label.fontSize = 16
        label.fontColor = currentTheme.buttonTextColor
        label.verticalAlignmentMode = .center
        button.addChild(label)
        
        backButton = button
        addChild(button)
    }
    
    // MARK: - Settings Button
    
    private func createSettingsButton() {
        let button = SKShapeNode(rectOf: CGSize(width: 60, height: 40))
        button.position = CGPoint(x: size.width - 50, y: size.height - 40)
        button.fillColor = currentTheme.buttonColor
        button.strokeColor = currentTheme.gridColor
        button.lineWidth = 1
        button.name = "settings_button"
        
        let label = SKLabelNode(text: "⚙️")
        label.fontSize = 20
        label.verticalAlignmentMode = .center
        button.addChild(label)
        
        settingsButton = button
        addChild(button)
    }
    
    // MARK: - Settings
    
    private func showSettings() {
        // Create settings container
        let container = SKShapeNode(rectOf: CGSize(width: 300, height: 200))
        container.position = CGPoint(x: size.width/2, y: size.height/2)
        container.fillColor = currentTheme.cellColor
        container.strokeColor = currentTheme.gridColor
        container.lineWidth = 2
        container.zPosition = 2
        containerBox = container
        addChild(container)
        
        // Settings title
        let titleLabel = SKLabelNode(text: "Settings")
        titleLabel.fontSize = 32
        titleLabel.fontColor = currentTheme.textColor
        titleLabel.position = CGPoint(x: size.width/2, y: size.height/2 + 60)
        titleLabel.zPosition = 3
        addChild(titleLabel)
        
        // Theme toggle button
        let themeButton = SKShapeNode(rectOf: CGSize(width: 150, height: 40))
        themeButton.fillColor = currentTheme.buttonColor
        themeButton.strokeColor = currentTheme.gridColor
        themeButton.lineWidth = 2
        themeButton.position = CGPoint(x: size.width/2, y: size.height/2)
        themeButton.zPosition = 3
        themeButton.name = "toggle_theme"
        
        let themeLabel = SKLabelNode(text: currentTheme.isDark ? "Light Theme" : "Dark Theme")
        themeLabel.fontSize = 20
        themeLabel.fontColor = currentTheme.buttonTextColor
        themeLabel.verticalAlignmentMode = .center
        themeButton.addChild(themeLabel)
        addChild(themeButton)
        
        // Close button
        let closeButton = SKShapeNode(rectOf: CGSize(width: 100, height: 40))
        closeButton.fillColor = currentTheme.buttonColor
        closeButton.strokeColor = currentTheme.gridColor
        closeButton.lineWidth = 2
        closeButton.position = CGPoint(x: size.width/2, y: size.height/2 - 60)
        closeButton.zPosition = 3
        closeButton.name = "close_settings"
        
        let closeLabel = SKLabelNode(text: "Close")
        closeLabel.fontSize = 20
        closeLabel.fontColor = currentTheme.buttonTextColor
        closeLabel.verticalAlignmentMode = .center
        closeButton.addChild(closeLabel)
        addChild(closeButton)
    }
    
    // MARK: - Theme Toggle
    
    private func toggleTheme() {
        currentTheme = currentTheme.isDark ? .light : .dark
        applyTheme()
    }
    
    // MARK: - Theme Application
    
    private func applyTheme() {
        backgroundColor = currentTheme.backgroundColor
        
        // Only update UI elements if they exist
        if !cells.isEmpty && !numbers.isEmpty && !currentBoard.isEmpty {
            // Update grid
            for row in 0..<gridSize {
                for col in 0..<gridSize {
                    cells[row][col].strokeColor = currentTheme.outlineColor
                    cells[row][col].fillColor = currentTheme.cellColor
                    
                    // Update number colors
                    if let text = numbers[row][col].text, !text.isEmpty {
                        if currentBoard[row][col] != 0 {
                            numbers[row][col].fontColor = currentTheme.initialNumberColor
                        } else {
                            numbers[row][col].fontColor = currentTheme.correctNumberColor
                        }
                    }
                }
            }
            
            // Update grid lines
            for node in children {
                if let line = node as? SKShapeNode, 
                   line.lineWidth == gridLineWidth {
                    line.strokeColor = currentTheme.outlineColor
                }
            }
        }
        
        // Update timer if it exists
        timerLabel?.fontColor = currentTheme.timerColor
        
        // Update buttons if they exist
        backButton?.fillColor = currentTheme.buttonColor
        backButton?.strokeColor = currentTheme.buttonStrokeColor
        if let label = backButton?.children.first as? SKLabelNode {
            label.fontColor = currentTheme.buttonTextColor
        }
        
        settingsButton?.fillColor = currentTheme.buttonColor
        settingsButton?.strokeColor = currentTheme.gridColor
        
        // Update number pad if it exists
        for node in children where node.name?.starts(with: "button_") == true {
            if let button = node as? SKShapeNode {
                button.fillColor = currentTheme.buttonColor
                button.strokeColor = currentTheme.gridColor
                if let label = button.children.first as? SKLabelNode {
                    label.fontColor = currentTheme.buttonTextColor
                }
            }
        }
    }
    
    // MARK: - Highlight Management
    
    /// Clears all cell highlights and animations
    private func clearAllHighlights() {
        for row in 0..<GridConstants.size {
            for col in 0..<GridConstants.size {
                cells[row][col].removeAction(forKey: "pulseAnimation")
                cells[row][col].removeAction(forKey: "scaleAnimation")
                cells[row][col].alpha = 1.0
                cells[row][col].setScale(1.0)
                cells[row][col].fillColor = currentTheme.cellColor
                cells[row][col].strokeColor = currentTheme.outlineColor
                cells[row][col].lineWidth = 1
            }
        }
    }
    
    /// Highlights all matching numbers on the board
    private func highlightAllMatchingNumbers(_ numberStr: String) {
        // Clear all previous highlights
        clearAllHighlights()
        
        // Highlight all matching numbers including the new one
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if numbers[row][col].text == numberStr || 
                   (initialBoard[row][col] != 0 && "\(initialBoard[row][col])" == numberStr) {
                    cells[row][col].fillColor = SKColor.yellow.withAlphaComponent(0.6)
                    cells[row][col].alpha = 1.0
                }
            }
        }
        
        // Make sure the newly filled number is also highlighted
        if let cell = selectedCell,
           numbers[cell.row][cell.col].text == numberStr {
            cells[cell.row][cell.col].fillColor = SKColor.yellow.withAlphaComponent(0.6)
            cells[cell.row][cell.col].alpha = 1.0
        }
    }
    
    // MARK: - Container Clearing
    
    private func clearAllContainers() {
        // Remove modal overlay
        modalOverlay?.removeFromParent()
        modalOverlay = nil
        
        // Remove game over elements
        gameOverNode?.removeFromParent()
        gameOverNode = nil
        
        // Remove container box
        containerBox?.removeFromParent()
        containerBox = nil
        
        // Remove difficulty title
        difficultyTitleLabel?.removeFromParent()
        difficultyTitleLabel = nil
        
        // Remove all buttons
        for button in difficultyButtons {
            button.removeFromParent()
        }
        difficultyButtons.removeAll()
        
        // Remove any other nodes that might be part of containers
        self.children.forEach { node in
            if node.zPosition >= 1 {  // All container elements have zPosition >= 1
                node.removeFromParent()
            }
        }
    }
    
    // Add this method to check and remove completed numbers
    private func checkAndRemoveCompletedNumber(_ number: String) {
        // Count how many times this number appears on the board
        var count = 0
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if numbers[row][col].text == number || 
                   (initialBoard[row][col] != 0 && "\(initialBoard[row][col])" == number) {
                    count += 1
                }
            }
        }
        
        // If the number appears 9 times (completed), remove its button
        if count == 9 {
            for node in children {
                if let button = node as? SKShapeNode,
                   button.name == "button_\(number)" {
                    // Fade out animation before removal
                    let fadeOut = SKAction.sequence([
                        SKAction.fadeOut(withDuration: 0.3),
                        SKAction.removeFromParent()
                    ])
                    button.run(fadeOut)
                }
            }
        }
    }
}
