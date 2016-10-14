import Foundation

open class FlowOperation: Operation {
  
  let identifier = UUID().uuidString
  weak var flowManager: Flow?
  
  
  
  open override func main() {
    flowManager?.operationWillStart(operation: self)
    mainLogic()
    flowManager?.operationDidFinish(operation: self)
  }
  
  open func mainLogic() {
    
  }
}
