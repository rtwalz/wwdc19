import UIKit
import SceneKit
import GameplayKit
import PlaygroundSupport

/*: pathfinding
 
 # Getting directions from one point to another
 Almost everybody has used a directions app to get from one place to another – whether it be by car, on foot, or by other means. Have you ever wondered how a computer can calculate how to get from one place to another almost instantly?
 
 Well, shortest path algorithms can find how to get from one place to another. Data with a list of **nodes** and **connections** is inputted into these algorithms. Put simply, you can think of nodes like places, and connections like the roads and streets that connect these places.
 
 
 ![Pathfinding Example Diagram](example.png)
 
 
 In the diagram above, points A, B, C, D, E, and F are all nodes. The lines connecting them together are connections. Let's say that you are at point F, and need to get to Point C with the fewest number of connections. You would need to go from F to E, E to A, A to B, and B to C, which is 4 connections. Pathfinding algorithms do exactly what we just did, but on a much larger and faster scale.
 
 ## Costs
 What if the connection between point A and E included a very tall mountain, but the connection between A and D was flat and short? In this case, we would rather avoid the mountain and take the easier way, even if it means more connections. The pathfinding algorithms can account for this. We can assign **costs** to connections, and the path with the lowest sum of costs will be preferred.
 
 ## With Swift
 We can use Swift to calculate directions using GameplayKit. It includes a handy GKGraph class, which can store GKGraphNodes and find a path between nodes.
 
 ## Instructions
 There is a 3 by 3 grid of nodes. Tap the **Run My Code** button. Check out the code below, and scroll to the bottom to change each node's cost and the destination and origin coordinates. Note that the origin of the grid is in the upper left.
 */

var grid = GKGridGraph(fromGridStartingAt: int2(0,0), width: 3, height: 3, diagonalsAllowed: false)

//#-hidden-code

class GridNode: GKGridGraphNode {
    var travelCosts: [GKGraphNode: Float] = [:]
    var generalCost: Float = Float(1)
    
    override func cost(to node: GKGraphNode) -> Float {
        return travelCosts[node] ?? 1
    }
    
    func general() -> Float {
        return generalCost
    }
    
    func changeCost(cost: Int){
        generalCost = Float(cost)
        var neighborNodes : [GKGraphNode] = []
        
        if (Int(self.gridPosition[0]) - 1) >= 0 {
            neighborNodes.append(grid.node(atGridPosition: [self.gridPosition[0]-1, self.gridPosition[1]])!)
        }
        
        if (Int(self.gridPosition[1]) - 1) >= 0 {
            neighborNodes.append(grid.node(atGridPosition: [self.gridPosition[0], self.gridPosition[1] - 1])!)
        }
        
        if (Int(self.gridPosition[0]) + 1) <= 2 {
            neighborNodes.append(grid.node(atGridPosition: [self.gridPosition[0]+1, self.gridPosition[1]])!)
        }
        
        if (Int(self.gridPosition[1]) + 1) <= 2 {
            neighborNodes.append(grid.node(atGridPosition: [self.gridPosition[0], self.gridPosition[1] + 1])!)
        }
        
        for neighbor in neighborNodes {
            travelCosts[neighbor] = generalCost
            (neighbor as? GridNode)?.travelCosts[self] = generalCost
        }
    }
}

grid = GKGridGraph(fromGridStartingAt: int2(0,0), width: 3, height: 3, diagonalsAllowed: false, nodeClass: GridNode.self)

let formatter = NumberFormatter()
formatter.minimumFractionDigits = 0
formatter.maximumFractionDigits = 2
formatter.numberStyle = .decimal

//#-end-hidden-code

// Wrapper function for changing the cost to go through a node
func changeCost(point: int2, cost: Int){
    ((grid.node(atGridPosition: [point[0], point[1]]))! as? GridNode)!.changeCost(cost: cost)
}

// Wrapper function for finding a path between two nodes
func getDirections(origin: int2, destination: int2) -> [GridNode]{
    return grid.findPath(from: grid.node(atGridPosition: origin)!, to: grid.node(atGridPosition: destination)!) as! [GridNode]
    
}
//#-editable-code Tap to write your code
// Try changing the costs, origin and destination to see what happens!
changeCost(point: int2(0,0), cost: 3)
changeCost(point: int2(1,2), cost: 10)
changeCost(point: int2(2,1), cost: 4)
let path = getDirections(origin: int2(0,0), destination: int2(2,2))
//#-end-editable-code

//#-hidden-code
class GridScene : SKScene {
    func getPixelCoordsFromGridCoords(x: Int, y: Int) -> CGPoint {
        return CGPoint(x: (x*125)+75, y: 400-((y*125)+75))
    }
    
    override init() {
        super.init(size: CGSize.zero)
        self.scaleMode = .resizeFill
        self.backgroundColor = .white
        
        let travelLine = SKShapeNode()
        let travelPath : CGMutablePath = CGMutablePath()
        
        for x in 0...2{
            for y in 0...2{
                let rectangle = SKShapeNode(rectOf: CGSize(width: 100, height: 100))
                rectangle.fillColor = .black
                if path[0].gridPosition[0] == Int32(x) && path[0].gridPosition[1] == Int32(y) {
                    rectangle.fillColor = UIColor(red:0.39, green:0.85, blue:0.22, alpha:1.0)
                } else if path.last?.gridPosition[0] == Int32(x) && path.last?.gridPosition[1] == Int32(y) {
                    rectangle.fillColor = UIColor(red:1.00, green:0.23, blue:0.19, alpha:1.0)
                }
                let thisRectanglePosition = getPixelCoordsFromGridCoords(x: x, y: y)
                rectangle.position = thisRectanglePosition
                let costOfThisNode = (grid.node(atGridPosition: [Int32(x), Int32(y)])! as? GridNode)!.general()
                let formattedCostOfThisNode = formatter.string(from: costOfThisNode as NSNumber) ?? "1"
                let costLabel = SKLabelNode()
                costLabel.text = formattedCostOfThisNode
                costLabel.zPosition = 3
                costLabel.position = CGPoint(x: thisRectanglePosition.x, y: thisRectanglePosition.y-22)
                
                costLabel.fontColor = .white
                costLabel.fontName = "Avenir"
                costLabel.fontSize = 60
                self.addChild(costLabel)
                self.addChild(rectangle)
                
            }
        }
        
        let firstPoint = getPixelCoordsFromGridCoords(x: Int(path[0].gridPosition[0]), y: Int(path[0].gridPosition[1]))
        travelPath.move(to: firstPoint)
        
        for point in path {
            let thisPoint = getPixelCoordsFromGridCoords(x: Int(point.gridPosition[0]), y: Int(point.gridPosition[1]))
            travelPath.addLine(to: CGPoint(x: thisPoint.x-38, y: thisPoint.y-38))
        }
        let lastNode = path.last!.gridPosition
        let lastPoint = getPixelCoordsFromGridCoords(x: Int(lastNode[0]), y: Int(lastNode[1]))
        travelPath.addLine(to: lastPoint)
        
        travelLine.strokeColor = UIColor(red:0.00, green:0.65, blue:0.99, alpha:1.0)
        travelLine.glowWidth = 0.5
        travelLine.lineWidth = 10
        travelLine.path = travelPath
        self.addChild(travelLine)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ViewController:UIViewController {
    let scene : GridScene = GridScene()
    let sceneView = SKView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
    
    override func viewDidLoad() {
        self.view.backgroundColor = .white
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
PlaygroundPage.current.assessmentStatus = .pass(message: "👏 It works! Try changing some of the variables to see how it affects the path, then go to the [next page.](@next)")

//#-end-hidden-code
