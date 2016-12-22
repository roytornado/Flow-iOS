import Foundation

public typealias FlowWillStartBlock = (Flow) -> Void
public typealias FlowDidFinishBlock = (Flow) -> Void

public class Flow {
  
  let internalOperationQueue = OperationQueue()
  private var treeNodes = [FlowOperationTreeNode]()
  private var currentNodeIndex = 0
  
  public var dataBucket = [String: Any]()
  public var isSuccess = true
  public var failedInfo: Any?

  
  private var willStartBlock: FlowWillStartBlock?
  private var didFinishBlock: FlowDidFinishBlock?
  
  public init() {
    setup()
  }
  
  func setup() {
  }
  
  public func setDataBucket(dataBucket: [String: Any]) -> Flow {
    self.dataBucket = dataBucket
    return self
  }
  
  public func setWillStartBlock(block: @escaping FlowWillStartBlock) -> Flow {
    willStartBlock = block
    return self
  }
  
  public func setDidFinishBlock(block: @escaping FlowDidFinishBlock) -> Flow {
    didFinishBlock = block
    return self
  }
  
  public func add(operation: FlowOperation, case: FlowCase? = nil) -> Flow {
    treeNodes.append(FlowOperationTreeNode(singleOperation: operation))
    return self
  }
  
  public func start() {
    currentNodeIndex = 0
    pickOperationToRun()
    callWillStartBlockAtMain()
  }
  
  public func operationWillStart(operation: FlowOperation) {
    Flow.log(message: "operationWillStart \(operation.displayName)")
  }
  
  public func operationDidFinish(operation: FlowOperation) {
    Flow.log(message: "operationDidFinish \(operation.displayName)")
    currentNodeIndex = currentNodeIndex + 1
    
    if currentNodeIndex < treeNodes.count {
      pickOperationToRun()
    } else {
      callDidFinishBlockAtMain()
    }
  }
  
  public func operationDidFailDueToInsufficientInputData(operation: FlowOperation) {
    Flow.log(message: "operationDidFailDueToInsufficientInputData \(operation.displayName)")
    isSuccess = false
    callDidFinishBlockAtMain()
  }
  
  public func operationDidFail(operation: FlowOperation, failedInfo: Any? = nil) {
    Flow.log(message: "operationDidFail \(operation.displayName)")
    isSuccess = false
    self.failedInfo = failedInfo
    callDidFinishBlockAtMain()
  }
  
  // MARK: Private
  private func pickOperationToRun() {
    let currentNode = treeNodes[currentNodeIndex]
    if let singleOperation = currentNode.singleOperation {
      singleOperation.flowManager = self
      internalOperationQueue.addOperation(singleOperation)
    }
  }
  
  private func callWillStartBlockAtMain() {
    DispatchQueue.main.async {
      self.willStartBlock?(self)
    }
  }
  
  private func callDidFinishBlockAtMain() {
    DispatchQueue.main.async {
      self.didFinishBlock?(self)
    }
  }
 
  static func log(message: String) {
    print("[Flow] \(message)")
  }
}
