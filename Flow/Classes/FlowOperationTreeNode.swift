import Foundation

class FlowOperationTreeNode {
  var childNodes = [FlowOperationTreeNode]()
  
  var flowCase: FlowCase?
  
  var isDummyNode = false
  
  var singleOperation: FlowOperation?
  
  var isGroup = false
  var operationCreator: FlowOperationCreator.Type!
  var dispatcher: FlowGroupDispatcher!
  var isFinished = false
  
  init() {
    self.isDummyNode = true
  }
  
  init(singleOperation: FlowOperation) {
    self.singleOperation = singleOperation
  }
  
  init(operationCreator: FlowOperationCreator.Type, dispatcher: FlowGroupDispatcher) {
    self.operationCreator = operationCreator
    self.dispatcher = dispatcher
    isGroup = true
  }
  
  func createGroupOperations(flow: Flow) -> [FlowOperation] {
    return dispatcher.createGroupOperations(flow: flow, operationCreator: operationCreator)
  }
  
  func postGroupOperation(flow: Flow, operation: FlowOperation) {
    dispatcher.collectOutput(flow: flow, op: operation)
    if dispatcher.isAllFinished {
      isFinished = true
    }
  }

}
