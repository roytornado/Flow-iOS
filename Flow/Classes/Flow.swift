import Foundation

public typealias FlowWillStartBlock = (Flow) -> Void
public typealias FlowDidFinishBlock = (Flow) -> Void

public class Flow {
  
  private static var runningFlow = [String: Flow]()
  
  final private let identifier = UUID().uuidString
  let internalLoggingQueue = OperationQueue()
  let internalCallbackQueue = OperationQueue()
  let internalOperationQueue = OperationQueue()
  private var rootNode = FlowOperationTreeNode()
  private var currentAddedNode: FlowOperationTreeNode!
  private var currentCasesRootNode: FlowOperationTreeNode?
  private var currentRunningNode: FlowOperationTreeNode?
  
  public var dataBucket = [String: Any]()
  public var isSuccess = true
  public var error: Error?
  
  private var willStartBlock: FlowWillStartBlock?
  private var didFinishBlock: FlowDidFinishBlock?
  private var logs = [String]()
  
  var isStopping = false
  var isRunning: Bool { return Flow.runningFlow[identifier] != nil }
  
  private func free() {
    Flow.runningFlow[self.identifier] = nil
  }
  
  public init() {
    Flow.runningFlow[identifier] = self
    setup()
  }
  
  func setup() {
    internalLoggingQueue.name = "LoggingQueue"
    internalLoggingQueue.qualityOfService = .userInteractive
    internalLoggingQueue.maxConcurrentOperationCount = 1
    internalCallbackQueue.maxConcurrentOperationCount = 1
    internalOperationQueue.maxConcurrentOperationCount = 1
    internalOperationQueue.qualityOfService = .userInteractive
    
    currentAddedNode = rootNode
  }
  
  @discardableResult public func setDataBucket(dataBucket: [String: Any]) -> Flow {
    self.dataBucket = dataBucket
    return self
  }
  
  @discardableResult public func setWillStartBlock(block: @escaping FlowWillStartBlock) -> Flow {
    willStartBlock = block
    return self
  }
  
  @discardableResult public func setDidFinishBlock(block: @escaping FlowDidFinishBlock) -> Flow {
    didFinishBlock = block
    return self
  }
  
  @discardableResult public func add(operation: FlowOperation, flowCase: FlowCase? = nil) -> Flow {
    let node = FlowOperationTreeNode(singleOperation: operation)
    if let flowCase = flowCase { node.flowCase = flowCase }
    addNodeToTree(node: node)
    return self
  }
  
  @discardableResult public func combine() -> Flow {
    combineCases()
    return self
  }
  
  @discardableResult public func addGrouped(operationCreator: FlowOperationCreator.Type, dispatcher: FlowGroupDispatcher) -> Flow {
    let node = FlowOperationTreeNode(operationCreator: operationCreator, dispatcher: dispatcher)
    addNodeToTree(node: node)
    return self
  }
  
  public func start() {
    var dataLog = "[DataBucket] start with:"
    dataBucket.forEach { key, value in
      dataLog += "\n\(key): \(value)"
    }
    log(message: dataLog)
    callWillStartBlockAtMain()
    currentRunningNode = rootNode
    pickOperationToRun()
  }
  
  public func operationWillStart(operation: FlowOperation) {
    log(message: "\(operation.displayName) WillStart")
    internalCallbackQueue.addOperation {
      self.internalOperationWillStart(operation: operation)
    }
  }
  
  private func internalOperationWillStart(operation: FlowOperation) {
  }
  
  public func operationDidFinish(operation: FlowOperation, type: FlowOperationStateFinishType) {
    if isStopping { return }
    internalCallbackQueue.addOperation {
      self.internalOperationDidFinish(operation: operation, type: type)
    }
  }
  
  private func internalOperationDidFinish(operation: FlowOperation, type: FlowOperationStateFinishType) {
    if isStopping { return }
    switch type {
    case .successfully:
      log(message: "\(operation.displayName) DidFinish: successfully")
      continuingCaseHandling(operation: operation)
      break
    case .withError(let error):
      log(message: "\(operation.displayName) DidFinish: withError: \(error)")
      stopingCaseHandling(operation: operation)
      break
    case .withInsufficientInputData(let message):
      log(message: "\(operation.displayName) DidFinish: withInsufficientInputData: \(message)")
      stopingCaseHandling(operation: operation)
      break
    case .withMismatchInputDataType(let message):
      log(message: "\(operation.displayName) DidFinish: withMismatchInputDataType: \(message)")
      stopingCaseHandling(operation: operation)
      break
    }
  }
  
  private func stopingCaseHandling(operation: FlowOperation) {
    let currentNode = currentRunningNode!
    if currentNode.isGroup {
      if !currentNode.dispatcher.allowFailure {
        log(message: "[Group] not allow failure in group. stop immediately.")
        internalOperationQueue.cancelAllOperations()
        isSuccess = false
        callDidFinishBlockAtMain()
      } else {
        continuingCaseHandling(operation: operation)
      }
    } else {
      isSuccess = false
      callDidFinishBlockAtMain()
    }
  }
  
  private func continuingCaseHandling(operation: FlowOperation) {
    let currentNode = currentRunningNode!
    if currentNode.isGroup {
      currentNode.postGroupOperation(flow: self, operation: operation)
      if !currentNode.isFinished {
        return
      }
    }
    pickOperationToRun()
  }
  
  public func setData(name: String, value: Any) {
    if let data = dataBucket[name] {
      log(message: "[DataBucket] replace for \(name): \(data) -> \(value)")
    } else {
      log(message: "[DataBucket] add for \(name): \(value)")
    }
    dataBucket[name] = value
  }
  
  // MARK: Private
  private func addNodeToTree(node: FlowOperationTreeNode) {
    if node.flowCase != nil {
      if let currentCasesRootNode = currentCasesRootNode {
        currentCasesRootNode.childNodes.append(node)
      } else {
        currentCasesRootNode = currentAddedNode
        currentAddedNode.childNodes.append(node)
      }
    } else {
      currentAddedNode.childNodes.append(node)
    }
    currentAddedNode = node
  }
  
  private func combineCases() {
    if let currentCasesRootNode = currentCasesRootNode {
      let dummyNode = FlowOperationTreeNode()
      currentAddedNode = dummyNode
      let leaves = currentCasesRootNode.findAllLeaves()
      for leaf in leaves {
        leaf.childNodes = [dummyNode]
      }
    }
    currentCasesRootNode = nil
  }
  
  private func pickOperationToRun() {
    var nextNode: FlowOperationTreeNode?
    let lastNode = currentRunningNode!
    if lastNode.childNodes.count == 1 {
      nextNode = lastNode.childNodes[0]
    } else if lastNode.childNodes.count > 1 {
      for child in lastNode.childNodes {
        if let flowCase = child.flowCase, let caseValue = dataBucket[flowCase.key] as? String, caseValue == flowCase.value! {
          nextNode = child
          break
        }
      }
      if nextNode == nil {
        log(message: "[Cases] no case is matached. finished in early.")
      }
    }
    
    guard let targetNode = nextNode else {
      callDidFinishBlockAtMain()
      return
    }
    currentRunningNode = targetNode
    if let singleOperation = targetNode.singleOperation {
      internalOperationQueue.maxConcurrentOperationCount = 1
      singleOperation.flowManager = self
      internalOperationQueue.addOperation(singleOperation)
    } else if targetNode.isGroup {
      internalOperationQueue.maxConcurrentOperationCount = targetNode.dispatcher.maxConcurrentOperationCount
      let operations = targetNode.createGroupOperations(flow: self)
      operations.forEach() { operation in
        operation.flowManager = self
        internalOperationQueue.addOperation(operation)
      }
      if operations.count == 0 {
        log(message: "[Group] no operation to run for group; please make sure the input data: <\(targetNode.dispatcher.inputKey!)> is not empty")
        isSuccess = false
        callDidFinishBlockAtMain()
      }
    } else if targetNode.isDummyNode {
      pickOperationToRun()
    }
  }
  
  private func callWillStartBlockAtMain() {
    DispatchQueue.main.async { [weak self] in
      if let me = self {
        me.willStartBlock?(me)
      }
    }
  }
  
  private func callDidFinishBlockAtMain() {
    isStopping = true
    var dataLog = "[DataBucket] end with:"
    dataBucket.forEach { key, value in
      dataLog += "\n\(key): \(value)"
    }
    log(message: dataLog)
    internalLoggingQueue.waitUntilAllOperationsAreFinished()
    DispatchQueue.main.async {
      self.didFinishBlock?(self)
      self.free()
    }
  }
  
  // MARK: Log & Summary
  public func log(message: String) {
    internalLoggingQueue.addOperation {
      self.internalLog(message: message)
    }
  }
  
  private func internalLog(message: String) {
    let df = DateFormatter()
    df.timeStyle = .medium
    let time = df.string(from: Date())
    logs.append("\(time) \(message)")
  }
  
  public func generateSummary() -> String {
    var summary = ""
    summary += "====== Flow Summary ======" + "\n"
    logs.forEach { summary += $0 + "\n" }
    summary += "Flow isSuccess: \(isSuccess)\n"
    summary += "======    Ending    ======" + "\n"
    return summary
  }
}
