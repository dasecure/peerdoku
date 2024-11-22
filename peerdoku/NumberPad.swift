import SpriteKit

class NumberPad {
    let height: CGFloat = 50
    let buttonWidth: CGFloat = 35
    let spacing: CGFloat = 5
    
    var buttons: [SKShapeNode] = []
    private let theme: Theme
    
    init(scene: SKScene, yPosition: CGFloat, theme: Theme) {
        self.theme = theme
        createNumberPad(in: scene, at: yPosition)
    }
    
    private func createNumberPad(in scene: SKScene, at yPosition: CGFloat) {
        let totalWidth = (buttonWidth * 9) + (spacing * 8)
        let startX = (scene.size.width - totalWidth) / 2
        
        for i in 1...9 {
            let button = createButton(number: i, x: startX + CGFloat(i - 1) * (buttonWidth + spacing))
            button.position.y = yPosition
            scene.addChild(button)
            buttons.append(button)
        }
    }
    
    private func createButton(number: Int, x: CGFloat) -> SKShapeNode {
        let button = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: height))
        button.position.x = x + buttonWidth/2
        button.fillColor = theme.buttonColor
        button.strokeColor = theme.buttonStrokeColor
        button.lineWidth = 1
        button.name = "button_\(number)"
        
        let label = SKLabelNode(text: "\(number)")
        label.fontName = "HelveticaNeue-Bold"
        label.fontSize = 20
        label.fontColor = theme.buttonTextColor
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: 0)
        
        button.addChild(label)
        return button
    }
} 