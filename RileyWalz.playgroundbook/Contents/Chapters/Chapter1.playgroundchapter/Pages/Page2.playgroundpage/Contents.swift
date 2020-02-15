import UIKit
import SpriteKit
import Foundation
import NaturalLanguage
import PlaygroundSupport

/*: naturallanguage
 
 # Parsing origin and destination from a query
 If you use a mapping app or voice assistant frequently, you are probably familiar with how you can type or say something like "Get directions from my house to the coffee shop." But you could rephrase your query to just "coffee shop from my house" and it would still work. How can it parse attributes like your journey's origin and destination when there are essentially infinite variations of the same request?
 
 ## Using Natural Language
 We can create an application that parses the origin and destination for a string of text using the Natural Language framework in Swift. I wrote down many examples of request queries and tagged which words were the origin and which were the destination.
 
 
 ![JSON tokens and labels](json.png)
 
 
 I then created a machine learning model using this data and Swift's CreateML framework, which is included in this playground.
 
 ## Instructions
 Check out how the code works below using Natural Language. Tap the **Run My Code** button. Then try changing the `text` variable to your own routing query, rerun the code and see how it parses it.
 */

//#-editable-code
let text = "How do I get from the softball game to the track practice?"
//#-end-editable-code
//#-hidden-code
class WordScene : SKScene {
    
var attributedText = NSMutableAttributedString(string: text, attributes: [
    NSAttributedString.Key.foregroundColor: UIColor.white,
    NSAttributedString.Key.font: UIFont.init(name: "Courier-Bold", size: 26)!
])
    
@available(iOSApplicationExtension 11.0, *)
    func displayText(){
        let queryLabel = SKLabelNode()
        queryLabel.attributedText = attributedText
        queryLabel.position = CGPoint(x: 200, y: 200)
        queryLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        queryLabel.numberOfLines = 0
        queryLabel.preferredMaxLayoutWidth = 325
        queryLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        self.addChild(queryLabel)

        let key = SKSpriteNode()
        key.position = CGPoint(x: 200, y: 100)

        let originKeyCircle = SKShapeNode(circleOfRadius: 9)
        originKeyCircle.fillColor = UIColor(red:0.39, green:0.85, blue:0.22, alpha:1.0)
        originKeyCircle.lineWidth = 0.5
        originKeyCircle.position = CGPoint(x: -50, y: 0)
        key.addChild(originKeyCircle)

        let destinationKeyCircle = originKeyCircle.copy() as! SKShapeNode
        destinationKeyCircle.fillColor = UIColor(red:1.00, green:0.23, blue:0.19, alpha:1.0)
        destinationKeyCircle.position = CGPoint(x: -50, y: -25)
        key.addChild(destinationKeyCircle)

        let originKeyLabel = SKLabelNode()
        originKeyLabel.fontName = "Courier"
        originKeyLabel.fontSize = 17
        originKeyLabel.text = "Origin"
        originKeyLabel.position = CGPoint(x: -2, y: -6)
        key.addChild(originKeyLabel)

        let destinationKeyLabel = originKeyLabel.copy() as! SKLabelNode
        destinationKeyLabel.text = "Destination"
        destinationKeyLabel.position = CGPoint(x: 25, y: -32)
        key.addChild(destinationKeyLabel)

        self.addChild(key)
    }
//#-end-hidden-code

func highlightWordsInString(range: NSRange, color: UIColor){
    attributedText.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
}
//#-hidden-code
override init() {
super.init(size: CGSize.zero)
self.scaleMode = .resizeFill
self.backgroundColor = UIColor(red:0.18, green:0.21, blue:0.25, alpha:1.0)
if #available(iOS 12.0, *){
//#-end-hidden-code

let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]

let originTagScheme = NLTagScheme("Origin")
let originTag = NLTag("ORIGIN")

let destinationTagScheme = NLTagScheme("Destination")
let destinationTag = NLTag("DEST")

// retrieve the compiled machine learning model
let modelURL = Bundle.main.url(forResource: "routing_query", withExtension: "mlmodelc")!
let queryTaggerModel = try! NLModel(contentsOf: modelURL)

let queryTagger = NLTagger(tagSchemes: [originTagScheme, destinationTagScheme])
queryTagger.string = text
queryTagger.setModels([queryTaggerModel], forTagScheme: originTagScheme)

queryTagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: originTagScheme, options: options) { (tag, tokenRange) -> Bool in
    if tag == originTag {
        // highlight words detected as an origin green
        self.highlightWordsInString(range: NSRange(tokenRange, in: text), color: UIColor(red:0.39, green:0.85, blue:0.22, alpha:1.0))
    }
    return true
}

queryTagger.setModels([queryTaggerModel], forTagScheme: destinationTagScheme)

queryTagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: destinationTagScheme, options: options) { (tag, tokenRange) -> Bool in
    if tag == destinationTag {
        // highlight words detected as a destination red
        self.highlightWordsInString(range: NSRange(tokenRange, in: text), color: UIColor(red:1.00, green:0.23, blue:0.19, alpha:1.0))
    }
    return true
}

//#-hidden-code
self.displayText()

} else {
print("Only iOS 12 and above is compatible with this demo.")
}

    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
class ViewController:UIViewController {
    let scene : WordScene = WordScene()
    let sceneView = SKView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
    
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor(red:0.18, green:0.21, blue:0.25, alpha:1.0)
        view.addSubview(sceneView)
        scene.scaleMode = .resizeFill
        sceneView.presentScene(scene)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sceneView.center = CGPoint(x: view.frame.width  / 2, y: view.frame.height / 2)
    }
}


PlaygroundPage.current.liveView = ViewController()
PlaygroundPage.current.assessmentStatus = .pass(message: "👏 It works! Try changing the `text` variable to another variation, then go to the [next page.](@next)")
//#-end-hidden-code
