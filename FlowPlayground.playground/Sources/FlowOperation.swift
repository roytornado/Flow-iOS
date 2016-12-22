import Foundation

public enum FlowOperationState {
  case idle, executing, finished
}

open class FlowOperation: Operation {
  
  let identifier = UUID().uuidString
  var flowManager: Flow!
  var state = FlowOperationState.idle {
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
  var failedInfo: Any?
  var isFinishedWithInsufficientInputData: Bool = false
  var isFinishedWithFailedOperation: Bool = false
  var isAsynchronousOperation = false
  var displayName: String {
    if let name = name {
      return name
    }
    return String(describing: type(of: self))
  }
  
  func free() {
    flowManager = nil
  }
  
  open override var isAsynchronous: Bool {
    return isAsynchronousOperation
  }
  
  open override var isExecuting: Bool {
    return state == .executing
  }
  
  open override var isFinished: Bool {
    return state == .finished
  }
  
  /**
   Should call this just before returing at main logic
   */
  open func startWithAsynchronous() {
    state = .executing
    waitUntilFinished()
  }
  
  open func finishWithAsynchronous() {
    state = .finished
  }
  
  open func getData(name: String, isOptional: Bool = false) -> Any? {
    if let data = flowManager.dataBucket[name] {
      return data
    }
    if !isOptional { isFinishedWithInsufficientInputData = true }
    return nil
  }
  
  open func setData(name: String, value: Any) {
    flowManager.dataBucket[name] = value
  }
  
  open override func main() {
    isFinishedWithInsufficientInputData = false
    flowManager.operationWillStart(operation: self)
    mainLogic()
    if isFinishedWithInsufficientInputData {
      flowManager.operationDidFailDueToInsufficientInputData(operation: self)
    } else if isFinishedWithFailedOperation {
      flowManager.operationDidFail(operation: self, failedInfo: failedInfo)
    } else {
      flowManager.operationDidFinish(operation: self)
    }
  }
  
  open func mainLogic() {
    
  }
}
