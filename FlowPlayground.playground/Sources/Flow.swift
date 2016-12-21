import Foundation

public class Flow {
  
  let internalOperationQueue = OperationQueue()
  private var treeNodes = [FlowOperationTreeNode]()
  private var currentNodeIndex = 0
  
  public var dataBucket = [String: Any]()
  
  public init() {
    setup()
  }
  
  func setup() {
  }
  
  public func setDataBucket(dataBucket: [String: Any]) -> Flow {
    self.dataBucket = dataBucket
    return self
  }
  
  public func add(operation: FlowOperation, case: FlowCase? = nil) -> Flow {
    treeNodes.append(FlowOperationTreeNode(singleOperation: operation))
    return self
  }
  
  public func start() {
    currentNodeIndex = 0
    pickOperationToRun()
  }
  
  public func operationWillStart(operation: FlowOperation) {
    Flow.log(message: "operationWillStart \(operation.displayName)")
  }
  
  public func operationDidFinish(operation: FlowOperation) {
    Flow.log(message: "operationDidFinish \(operation.displayName)")
    currentNodeIndex = currentNodeIndex + 1
    pickOperationToRun()
  }
  
  public func operationDidFailDueToInsufficientInputData(operation: FlowOperation) {
    Flow.log(message: "operationDidFailDueToInsufficientInputData \(operation.displayName)")
  }
  
  public func operationDidFail(operation: FlowOperation) {
    Flow.log(message: "operationDidFail \(operation.displayName)")
  }
  
  // MARK: Private
  private func pickOperationToRun() {
    let currentNode = treeNodes[currentNodeIndex]
    if let singleOperation = currentNode.singleOperation {
      singleOperation.flowManager = self
      internalOperationQueue.addOperation(singleOperation)
    }
  }
 
  static func log(message: String) {
    print("[Flow] \(message)")
  }
}
