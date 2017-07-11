import Foundation

public enum FlowOperationState {
  case idle, executing, finished(FlowOperationStateFinishType)
}

public enum FlowOperationStateFinishType {
  case successfully, withError(Error), withInsufficientInputData(String), withMismatchInputDataType(String)
}

public protocol FlowOperationCreator {
  static func create() -> FlowOperation
}

open class FlowOperation: Operation {
  
  final public let identifier = UUID().uuidString
  internal var groupTag: Any?
  internal var groupDataBucket: [String: Any]?
  open var primaryInputParamKey: String { return "" }
  open var primaryOutputParamKey: String { return "" }
  weak var flowManager: Flow?
  public var state = FlowOperationState.idle {
    willSet {
      switch(state, newValue){
      case (.idle, .executing):
        willChangeValue(forKey: "isExecuting")
      case (.idle, .finished):
        willChangeValue(forKey: "isFinished")
      case (.executing, .finished):
        willChangeValue(forKey: "isExecuting")
        willChangeValue(forKey: "isFinished")
      default: break
      }
    }
    didSet{
      switch(oldValue, state){
      case (.idle, .executing):
        didChangeValue(forKey: "isExecuting")
      case (.idle, .finished):
        didChangeValue(forKey: "isFinished")
      case (.executing, .finished):
        didChangeValue(forKey: "isExecuting")
        didChangeValue(forKey: "isFinished")
      default: break
      }
    }
  }
  var isAsynchronousOperation = false
  
  public var displayName: String {
    var result = ""
    if let name = name {
      result =  name
    } else {
      result = String(describing: type(of: self))
    }
    if groupDataBucket != nil {
      result = result + " " + identifier.substring(to: identifier.index(identifier.startIndex, offsetBy: 4))
    }
    return "[\(result)]"
  }
  
  internal func free() {
    flowManager = nil
  }
  
  final public override var isAsynchronous: Bool {
    return isAsynchronousOperation
  }
  
  final public override var isConcurrent: Bool {
    return isAsynchronousOperation
  }
  
  final public override var isExecuting: Bool {
    switch state {
    case .executing:
      return true
    default:
      return false
    }
  }
  
  final public override var isFinished: Bool {
    switch state {
    case .finished:
      return true
    default:
      return false
    }
  }
  
  /**
   Should call this just before returing at main logic
   */
  public func startWithAsynchronous() {
    isAsynchronousOperation = true
    state = .executing
  }
  
  public func finishSuccessfully() {
    state = .finished(.successfully)
    callbackToFlow()
  }
  
  public func finishWithError(error: Error) {
    state = .finished(.withError(error))
    callbackToFlow()
  }
  
  public func getData<T>(name: String, isOptional: Bool = false) -> T? {
    guard let flowManager = flowManager else { return nil }
    var dataBucket = flowManager.dataBucket
    if let groupDataBucket = groupDataBucket {
      dataBucket = groupDataBucket
    }
    if let data = dataBucket[name] as? T {
      return data
    }
    if !isOptional {
      if let data = dataBucket[name] {
        let message = "<\(name)> in data bucket is <\(data)> with type <\(type(of: data))>, but NOT type <\(T.self)>."
        state = .finished(.withMismatchInputDataType(message))
      } else {
        let message = "can't find <\(name)> in data bucket"
        state = .finished(.withInsufficientInputData(message))
      }
      callbackToFlow()
    }
    return nil
  }
  
  public func setData(name: String, value: Any) {
    guard let flowManager = flowManager else { return }
    if var dataBucket = groupDataBucket {
      dataBucket[name] = value
      groupDataBucket = dataBucket
    } else {
      flowManager.setData(name: name, value: value)
    }
  }
  
  // It's called by FlowManager. Don't override it.
  final public override func main() {
    if isCancelled {
      return
    }
    flowManager?.operationWillStart(operation: self)
    mainLogic()
  }
  
  private func callbackToFlow() {
    switch state {
    case .finished(let type):
      flowManager?.operationDidFinish(operation: self, type: type)
      break
    default:
      finishSuccessfully()
      flowManager?.operationDidFinish(operation: self, type: .successfully)
      break
    }
    free()
  }
  
  // Override and place your logic here
  open func mainLogic() {
    
  }
  
  // MARK: Log & Summary
  public func log(message: String) {
    flowManager?.log(message: "\(displayName) \(message)")
  }
}
