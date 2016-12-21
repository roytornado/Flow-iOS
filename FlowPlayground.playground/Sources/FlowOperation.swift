import Foundation

open class FlowOperation: Operation {
  
  let identifier = UUID().uuidString
  var flowManager: Flow!
  var isFinishedWithInsufficientInputData: Bool = false
  var isFinishedWithFailedOperation: Bool = false
  var displayName: String {
    if let name = name {
      return name
    }
    return String(describing: type(of: self))
  }
  
  func free() {
    flowManager = nil
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
      flowManager.operationDidFail(operation: self)
    } else {
      flowManager.operationDidFinish(operation: self)
    }
  }
  
  open func mainLogic() {
    
  }
}
