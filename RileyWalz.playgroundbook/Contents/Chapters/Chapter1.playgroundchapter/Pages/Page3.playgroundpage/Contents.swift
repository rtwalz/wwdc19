import UIKit
import Foundation
import SpriteKit
import GameplayKit
import AVFoundation
import NaturalLanguage
import PlaygroundSupport

/*: example
 
 # Application example
 Let's combine both of the features of Swift we just learned about – finding a path between two points using a GKGridGraph, and word tagging with Natural Language – to create a directions demo. This demo can take a routing query, like "school to cafe", process which nodes are mentioned, and generate a route between the two detected nodes. But to keep things interesting, we'll add a random incident that adds a cost somewhere on the map. This can be anything from a train crossing to construction work.
 
 ## Instructions
 Check out how the code works below. Tap the **Run My Code** button. Try changing the variables at the top and rerunning the program to see how it affects the map.
 */

// The routing query for this map. The list of places is defined below as placesOfInterestList.
//#-editable-code
let query = "Cafe from library"
//#-end-editable-code

// The number of seconds between each new incident
//#-editable-code
let newObstacleInterval: Int = 3
//#-end-editable-code

// The number of seconds that an obstacle lasts before being removed from the graph and grid
//#-editable-code
let obstacleDuration: Int = 16
//#-end-editable-code

//#-hidden-code
typealias scenarios = [scenario]

struct scenario: Codable {
    let name: String
    let cost: Int
    let symbol: String
}


typealias places = [place]

struct place: Codable {
    let name: String
    let location: [Int]
}
//#-end-hidden-code
// This is a list of places that can be navigated to and from, along with their coordinates
//#-editable-code
let placesOfInterestList: places = [
    place(name: "School", location: [1,1]),
    place(name: "Cafe", location: [7,1]),
    place(name: "Bakery", location: [3,3]),
    place(name: "Library", location: [1,7])
]
//#-end-editable-code

// This is a list of possible incidents that can happen, and the cost it adds to a node
//#-editable-code
let possibleTrafficScenarios: scenarios = [
    scenario(name: "Heavy traffic", cost: 4, symbol: "🚦"),
    scenario(name: "Ambulance", cost: 2, symbol: "🚑"),
    scenario(name: "Police activity", cost: 3, symbol: "🚔"),
    scenario(name: "School bus", cost: 2, symbol: "🚌"),
    scenario(name: "Train crossing", cost: 3, symbol: "🚂"),
    scenario(name: "Car accident", cost: 6, symbol: "💥"),
    scenario(name: "Fire truck", cost: 2, symbol: "🚒"),
    scenario(name: "School zone", cost: 3, symbol: "🚸"),
    scenario(name: "Construction", cost: 3, symbol: "🚧"),
    scenario(name: "Road closed", cost: 1000, symbol: "🚫"),
]
//#-end-editable-code

//#-hidden-code
let obstacleMP3 = URL(fileURLWithPath: Bundle.main.path(forResource: "obstacle", ofType: "mp3")!)
let arrivedMP3 = URL(fileURLWithPath: Bundle.main.path(forResource: "arrived", ofType: "mp3")!)
var audioPlayer = AVAudioPlayer()
//#-end-hidden-code

class GridNode: GKGridGraphNode {
    var travelCosts: [GKGraphNode: Float] = [:]
   
    override func cost(to node: GKGraphNode) -> Float {
        return travelCosts[node] ?? 1
    }
    
    func changeCost(cost: Float){
        var neighborNodes : [GKGraphNode] = []
        
        // check for any adjacent nodes and add a cost to their connections
        if (Int(self.gridPosition[0]) - 1) >= 0 {
            neighborNodes.append(grid.node(atGridPosition: [self.gridPosition[0]-1, self.gridPosition[1]])!)
        }
        if (Int(self.gridPosition[1]) - 1) >= 0 {
            neighborNodes.append(grid.node(atGridPosition: [self.gridPosition[0], self.gridPosition[1] - 1])!)
        }
        
        if (Int(self.gridPosition[0]) + 1) <= 8 {
            neighborNodes.append(grid.node(atGridPosition: [self.gridPosition[0]+1, self.gridPosition[1]])!)
        }
        
        if (Int(self.gridPosition[1]) + 1) <= 8 {
            neighborNodes.append(grid.node(atGridPosition: [self.gridPosition[0], self.gridPosition[1] + 1])!)
        }
        
        for neighbor in neighborNodes {
            travelCosts[neighbor] = cost
            (neighbor as? GridNode)?.travelCosts[self] = cost
        }
    }
}

let grid = GKGridGraph(fromGridStartingAt: int2(0,0), width: 9, height: 9, diagonalsAllowed: false, nodeClass: GridNode.self)

class MapScene : SKScene {
    //#-hidden-code
    let currentLocation = SKShapeNode(circleOfRadius: 8)
    let origin = SKShapeNode(circleOfRadius: 7)
    let destination = SKShapeNode(circleOfRadius: 7)
    var pointsQueue: Array<vector_int2> = []
    var moveDotTimer: Timer!
    var newObstacleTimer: Timer!
    var viewSquareEdgeLength : Int = 400
    var viewSquareEdgeOffset: Int = 0
    
    var futureTravelLine = SKShapeNode()
    var pastTravelLine = SKShapeNode()
    
    let linePathForPast : CGMutablePath = CGMutablePath()
    
    var firstDoneYet:Bool = false
    var originGridPoint: vector_int2 = vector_int2(0, 0)
    var destinationGridPoint: vector_int2 = vector_int2(0, 0)
    
    func displayBanner(text: String){
        
        let banner = SKShapeNode(rectOf: CGSize(width: 350, height: 50), cornerRadius: 20)
        banner.position = CGPoint(x: 200, y: 460)
        banner.fillColor = UIColor(red:1.00, green:1.00, blue:1.00, alpha:0.9)
        banner.zPosition = 2
        self.addChild(banner)
        
        let bannerTextString = SKLabelNode()
        bannerTextString.text = text
        bannerTextString.zPosition = 3
        bannerTextString.fontColor = .black
        bannerTextString.fontName = "Avenir"
        bannerTextString.fontSize = 18
        bannerTextString.position = CGPoint(x: 200, y: 455)
        self.addChild(bannerTextString)
        
        let animationEnter = SKAction.sequence([
            SKAction.wait(forDuration: 1),
            SKAction.moveBy(x: 0, y: -110, duration: 0.25),
            SKAction.moveBy(x: 0, y: 10, duration: 0.4)
        ])
        
        let animationExit = SKAction.sequence([
            SKAction.wait(forDuration: 3),
            SKAction.moveBy(x: 0, y: -10, duration: 0.4),
            SKAction.moveBy(x: 0, y: 110, duration: 0.25)
        ])
        
        banner.run(animationEnter)
        bannerTextString.run(animationEnter)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            banner.run(animationExit)
            bannerTextString.run(animationExit, completion: {
                banner.removeFromParent()
                bannerTextString.removeFromParent()
            })
        }
    }
    
    
    //#-end-hidden-code
    func getApproachingStreetCorner() -> vector_int2 {
        if pointsQueue.isEmpty == false {
            return pointsQueue[0]
        } else {
            return originGridPoint
        }
    }
    
    func getPixelCoordsFromGridCoords(x: Int, y: Int) -> Array<Int> {
        return [(x*49)+4, 400-((y*49)+4)]
    }
    
    func setRouteOriginAndDestination(originHere: vector_int2, destinationHere: vector_int2){
        self.originGridPoint = originHere
        self.destinationGridPoint = destinationHere
        //#-hidden-code
        let originPoint = self.getPixelCoordsFromGridCoords(x: Int(originHere[0]), y: Int(originHere[1]))
        let destinationPoint = self.getPixelCoordsFromGridCoords(x: Int(destinationHere[0]), y: Int(destinationHere[1]))

        self.origin.position = CGPoint(x: originPoint[0], y: originPoint[1])
        self.destination.position = CGPoint(x: destinationPoint[0], y: destinationPoint[1])
        self.origin.fillColor = UIColor(red:0.39, green:0.85, blue:0.22, alpha:1.0)
        self.destination.fillColor = UIColor(red:1.00, green:0.23, blue:0.19, alpha:1.0)
        self.addChild(self.origin)
        self.addChild(self.destination)
        
        self.currentLocation.position = CGPoint(x: originPoint[0], y: originPoint[1])
        self.addChild(currentLocation)
        //#-end-hidden-code
    }
    
    func startJourney(){
        recalculation()
        //#-hidden-code
        moveDotTimer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(moveDot), userInfo: nil, repeats: true) // animate the motion of the location beacon every 1.5 seconds
        //#-end-hidden-code
        newObstacleTimer = Timer.scheduledTimer(timeInterval: TimeInterval(newObstacleInterval), target: self, selector: #selector(newObstacle), userInfo: nil, repeats: true) // make a new obstacle every certain nummber of seconds
    }
    
    @objc func newObstacle(){
        let randomObstacle = possibleTrafficScenarios.randomElement()!
        let randomXGridCoordinate :Int
        let randomYGridCoordinate :Int
        //#-hidden-code
        if pointsQueue.count > 4 {
            var modifiedPointsQueue:[vector_int2] = pointsQueue
            modifiedPointsQueue.removeFirst()
            modifiedPointsQueue.removeLast()
            modifiedPointsQueue.removeLast()
            let randomPointFromQueue = modifiedPointsQueue.randomElement()!
            randomXGridCoordinate = Int(randomPointFromQueue[0])
            randomYGridCoordinate = Int(randomPointFromQueue[1])
        } else {
            randomXGridCoordinate = Int.random(in: 1 ..< 8)
            randomYGridCoordinate = Int.random(in: 1 ..< 8)
        }
        
        let randomPixelCoordinate = self.getPixelCoordsFromGridCoords(x: randomXGridCoordinate, y: randomYGridCoordinate)
        
        let obstaclePin = SKSpriteNode(imageNamed: "obstacle_pin")
        obstaclePin.position = CGPoint(x: randomPixelCoordinate[0], y: randomPixelCoordinate[1]+19)
        obstaclePin.size = CGSize(width: 25, height: 25)
        let ObstacleEmojiIcon = SKLabelNode()
        ObstacleEmojiIcon.text = randomObstacle.symbol
        ObstacleEmojiIcon.fontSize = 10
        ObstacleEmojiIcon.position = CGPoint(x: randomPixelCoordinate[0]-2, y: randomPixelCoordinate[1]+17)
        self.addChild(obstaclePin)
        self.addChild(ObstacleEmojiIcon)
        let animationG = SKAction.sequence([
            SKAction.scale(by: 2.5, duration: 0.1),
            SKAction.scale(by: 0.6, duration: 0.25)
        ])
        obstaclePin.run(animationG)
        ObstacleEmojiIcon.run(animationG)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: obstacleMP3)
            audioPlayer.play()
        } catch {
            fatalError("audio file not found")
        }
        //#-end-hidden-code
        
        let coordsForGridNode:vector_int2 = [Int32(randomXGridCoordinate), Int32(randomYGridCoordinate)]
        let gridNode = grid.node(atGridPosition: coordsForGridNode)! as? GridNode
        gridNode!.changeCost(cost: Float(randomObstacle.cost))
        
        // recalculate 1 second after adding an incident
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.recalculation()
        }
        
        // remove the incident number of seconds after it is added to the map
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(obstacleDuration)) {
            gridNode!.changeCost(cost: 0)
            obstaclePin.removeFromParent()
            ObstacleEmojiIcon.removeFromParent()
        }
    }
    
    @objc func recalculation(){
        //#-hidden-code
        var originPointForRecalculation : vector_int2
        if pointsQueue.isEmpty == false && firstDoneYet == true {
            originPointForRecalculation = pointsQueue[0]
        } else if pointsQueue.isEmpty == true && firstDoneYet == true{
            return
        } else {
            originPointForRecalculation = originGridPoint
        }
        
        let linePathForFuture : CGMutablePath = CGMutablePath()
        //#-end-hidden-code
        let path = grid.findPath(from: grid.node(atGridPosition: originPointForRecalculation)!, to: grid.node(atGridPosition: destinationGridPoint)!) as! [GridNode]
        var nextPoint = self.getApproachingStreetCorner()
        
        let firstPoint = self.getPixelCoordsFromGridCoords(x: Int(nextPoint[0]), y: Int(nextPoint[1]))
        
        var updatedPointsQueue:[vector_int2] = []
        //#-hidden-code
        linePathForFuture.move(to: CGPoint(x:firstPoint[0], y:firstPoint[1]))
        //#-end-hidden-code
        for point in path {
            updatedPointsQueue.append(point.gridPosition)
            let newPoint = self.getPixelCoordsFromGridCoords(x: Int(point.gridPosition[0]), y: Int(point.gridPosition[1]))
            //#-hidden-code
            linePathForFuture.addLine(to: CGPoint(x:newPoint[0], y:newPoint[1]))
            //#-end-hidden-code
        }
        //#-hidden-code
        self.futureTravelLine.path = linePathForFuture
        //#-end-hidden-code
        pointsQueue = updatedPointsQueue
    }
    //#-hidden-code
    @objc func moveDot(){
        if pointsQueue.isEmpty == false {

            var locationToMoveTo = self.getPixelCoordsFromGridCoords(x: Int(pointsQueue[0][0]), y: Int(pointsQueue[0][1]))
           
            self.currentLocation.run(SKAction.move(to: CGPoint(x: locationToMoveTo[0], y: locationToMoveTo[1]), duration: 1.5))
            //firstDoneYet:Bool = false
            if firstDoneYet == false {
                let firstPointAsPixelCoordinate = self.getPixelCoordsFromGridCoords(x: Int(originGridPoint[0]), y: Int(originGridPoint[1]))
                self.linePathForPast.move(to: CGPoint(x: firstPointAsPixelCoordinate[0], y: firstPointAsPixelCoordinate[1]))
                self.pastTravelLine.path = self.linePathForPast
                firstDoneYet = true
            } else {
                let previousPointAsPixelCoordinate = self.getPixelCoordsFromGridCoords(x: Int(pointsQueue[0][0]), y: Int(pointsQueue[0][1]))
                self.linePathForPast.addLine(to: CGPoint(x: previousPointAsPixelCoordinate[0], y: previousPointAsPixelCoordinate[1]))
                self.pastTravelLine.path = self.linePathForPast
                pointsQueue.removeFirst()
            }
        } else {
            self.displayBanner(text: "You've arrived at your destination")
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: arrivedMP3)
                audioPlayer.play()
            } catch {
                fatalError("audio file not found")
            }
            moveDotTimer.invalidate()
            newObstacleTimer.invalidate()
        }
    }

    override init() {
        super.init(size: CGSize.zero)
        self.scaleMode = .resizeFill
       
        self.currentLocation.fillColor = UIColor(red:0.02, green:0.49, blue:1.00, alpha:1.0)
        self.currentLocation.strokeColor = .white
        self.currentLocation.lineWidth = 4
        self.currentLocation.zPosition = 2
        
        self.futureTravelLine.strokeColor = UIColor(red:0.00, green:0.65, blue:0.99, alpha:1.0)
        self.futureTravelLine.glowWidth = 0.5
        self.futureTravelLine.lineWidth = 5
        self.addChild(futureTravelLine)
        
        self.pastTravelLine.strokeColor = UIColor(red:0.00, green:0.65, blue:0.99, alpha:1.0)
        self.pastTravelLine.glowWidth = 0.5
        self.pastTravelLine.lineWidth = 5
        self.addChild(pastTravelLine)
        
    }
    
    override func didMove(to view: SKView) {
        let baseMap = SKSpriteNode(imageNamed: "base_map")
        baseMap.zPosition = -1
        baseMap.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(baseMap)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //#-end-hidden-code
}

class ViewController: UIViewController {
    let scene: MapScene = MapScene()
    //#-hidden-code
    let sceneView = SKView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
    //#-end-hidden-code

    override func viewDidLoad() {
        //#-hidden-code
        self.view.backgroundColor = UIColor(red:0.99, green:0.99, blue:0.87, alpha:1.0)
        if #available(iOS 12.0, *) {
        //#-end-hidden-code
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        
        let originTagScheme = NLTagScheme("Origin")
        let originTag = NLTag("ORIGIN")
        
        let destinationTagScheme = NLTagScheme("Destination")
        let destinationTag = NLTag("DEST")
        let modelURL = Bundle.main.url(forResource: "routing_query", withExtension: "mlmodelc")!
        let queryTaggerModel = try! NLModel(contentsOf: modelURL)

        let queryTagger = NLTagger(tagSchemes: [originTagScheme, destinationTagScheme])
        queryTagger.string = query
        queryTagger.setModels([queryTaggerModel], forTagScheme: originTagScheme)

        var detectedOrigin: [Int] = []
        var detectedDestination: [Int] = []
        
        var detectedOriginName: String = ""
        var detectedDestinationName: String = ""

        queryTagger.enumerateTags(in: query.startIndex..<query.endIndex, unit: .word, scheme: originTagScheme, options: options) { (tag, tokenRange) -> Bool in
            if tag == originTag {
                for placeCheck in placesOfInterestList {
                    if query[tokenRange].lowercased().contains(placeCheck.name.lowercased()) {
                        detectedOrigin = [placeCheck.location[0], placeCheck.location[1]]
                        detectedOriginName = placeCheck.name.lowercased()
                        
                    }
                }
            }
            return true
        }

        queryTagger.setModels([queryTaggerModel], forTagScheme: destinationTagScheme)

        queryTagger.enumerateTags(in: query.startIndex..<query.endIndex, unit: .word, scheme: destinationTagScheme, options: options) { (tag, tokenRange) -> Bool in
            if tag == destinationTag {
                for placeCheck in placesOfInterestList {
                    if query[tokenRange].lowercased().contains(placeCheck.name.lowercased()) {
                        detectedDestination = [placeCheck.location[0], placeCheck.location[1]]
                        detectedDestinationName = placeCheck.name.lowercased()
                    }
                }
            }
            return true
        }
        
        
        if detectedOrigin.isEmpty == false && detectedDestination.isEmpty == false {
            scene.displayBanner(text: "Getting directions from \(detectedOriginName) to \(detectedDestinationName)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { //seconds for obstacle to last
                self.scene.setRouteOriginAndDestination(originHere: vector_int2(Int32(detectedOrigin[0]),Int32(detectedOrigin[1])), destinationHere: vector_int2(Int32(detectedDestination[0]),Int32(detectedDestination[1])))
                self.scene.startJourney()
            }
        } else {
            scene.displayBanner(text: "Could not detect a destination and origin from your query")
        }
    //#-hidden-code
    }
        view.addSubview(sceneView)
        scene.scaleMode = .resizeFill
        sceneView.presentScene(scene)
    //#-end-hidden-code
    }
    //#-hidden-code
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sceneView.center = CGPoint(x: view.frame.width  / 2, y: view.frame.height / 2)
    }
    //#-end-hidden-code
}
//#-hidden-code
PlaygroundPage.current.liveView = ViewController()
PlaygroundPage.current.assessmentStatus = .pass(message: "👏 Nice job! Try changing the editable variables at the top to see how it affects the map. [Next page](@next)")
//#-end-hidden-code
