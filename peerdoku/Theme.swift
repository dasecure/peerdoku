import SpriteKit

struct Theme {
    // Basic colors
    let backgroundColor: SKColor
    let gridColor: SKColor
    let textColor: SKColor
    let cellColor: SKColor
    
    // Highlight and interaction colors
    let highlightColor: SKColor
    let selectedCellColor: SKColor
    let matchingNumbersColor: SKColor
    
    // Button colors
    let buttonColor: SKColor
    let buttonTextColor: SKColor
    let buttonStrokeColor: SKColor
    
    // Number colors
    let initialNumberColor: SKColor
    let correctNumberColor: SKColor
    let wrongNumberColor: SKColor
    
    // UI element colors
    let timerColor: SKColor
    let outlineColor: SKColor
    let modalOverlayColor: SKColor
    let containerColor: SKColor
    let containerStrokeColor: SKColor
    let errorColor: SKColor
    
    // Difficulty button colors
    let easyButtonColor: SKColor
    let mediumButtonColor: SKColor
    let hardButtonColor: SKColor
    let expertButtonColor: SKColor
    
    let isDark: Bool
    
    static let light = Theme(
        backgroundColor: .white,
        gridColor: SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0),
        textColor: SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0),
        cellColor: .white,
        highlightColor: SKColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 0.4),
        selectedCellColor: SKColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 0.5),
        matchingNumbersColor: SKColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 0.3),
        buttonColor: SKColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0),
        buttonTextColor: SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0),
        buttonStrokeColor: SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0),
        initialNumberColor: SKColor(red: 0.0, green: 0.4, blue: 0.8, alpha: 1.0),
        correctNumberColor: SKColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1.0),
        wrongNumberColor: SKColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0),
        timerColor: SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0),
        outlineColor: SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0),
        modalOverlayColor: SKColor.black.withAlphaComponent(0.5),
        containerColor: .white,
        containerStrokeColor: .black,
        errorColor: SKColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0),
        easyButtonColor: .green,
        mediumButtonColor: .yellow,
        hardButtonColor: .orange,
        expertButtonColor: .red,
        isDark: false
    )
    
    static let dark = Theme(
        backgroundColor: SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0),
        gridColor: .white,
        textColor: SKColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1.0),
        cellColor: SKColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0),
        highlightColor: SKColor(red: 0.3, green: 0.3, blue: 0.5, alpha: 0.4),
        selectedCellColor: SKColor(red: 0.7, green: 0.5, blue: 0.9, alpha: 0.5),
        matchingNumbersColor: SKColor(red: 0.3, green: 0.3, blue: 0.5, alpha: 0.3),
        buttonColor: SKColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1.0),
        buttonTextColor: SKColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1.0),
        buttonStrokeColor: .white,
        initialNumberColor: SKColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 1.0),
        correctNumberColor: SKColor(red: 0.5, green: 1.0, blue: 0.5, alpha: 1.0),
        wrongNumberColor: SKColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0),
        timerColor: SKColor(red: 0.9, green: 0.9, blue: 1.0, alpha: 1.0),
        outlineColor: .white,
        modalOverlayColor: SKColor.black.withAlphaComponent(0.5),
        containerColor: SKColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1.0),
        containerStrokeColor: .white,
        errorColor: SKColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0),
        easyButtonColor: SKColor(red: 0.3, green: 0.7, blue: 0.3, alpha: 1.0),
        mediumButtonColor: SKColor(red: 0.7, green: 0.7, blue: 0.3, alpha: 1.0),
        hardButtonColor: SKColor(red: 0.7, green: 0.5, blue: 0.3, alpha: 1.0),
        expertButtonColor: SKColor(red: 0.7, green: 0.3, blue: 0.3, alpha: 1.0),
        isDark: true
    )
} 
