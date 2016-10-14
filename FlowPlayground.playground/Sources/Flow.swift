import Foundation

public class Flow {
  
  let internalOperationQueue = OperationQueue()
  var treeNodes = [FlowOperationTreeNode]()
  var rootNode: FlowOperationTreeNode?
  public var dataBucket = [String: Any]()
  
  public init() {
    
  }
  
  
  public func add(operation: FlowOperation, case: FlowCase? = nil) {
    treeNodes.append(FlowOperationTreeNode(singleOperation: operation))
  }
  
  public func start() {
    for treeNode in treeNodes {
      if let singleOperation = treeNode.singleOperation {
        singleOperation.flowManager = self
        internalOperationQueue.addOperation(singleOperation)
      }
    }
  }
  
  public func operationWillStart(operation: FlowOperation) {
    Flow.log(message: "operationWillStart \(operation.name)")
  }
  
  public func operationDidFinish(operation: FlowOperation) {
    Flow.log(message: "operationDidFinish \(operation.name)")

  }
 
  public static func log(message: String) {
    print("[Flow] \(message)")
  }
}
