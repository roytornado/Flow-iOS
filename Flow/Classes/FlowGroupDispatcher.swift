import Foundation

public class FlowGroupDispatcher {
  var maxConcurrentOperationCount = 3
  var allowFailure = false
  var inputKey: String!
  var outputKey: String!
  
  var operationsSize = 0
  var finishedFlags = [Bool]()
  
  public init(inputKey: String, outputKey: String, maxConcurrentOperationCount: Int = 3, allowFailure: Bool = false) {
    self.inputKey = inputKey
    self.outputKey = outputKey
    self.maxConcurrentOperationCount = maxConcurrentOperationCount
    self.allowFailure = allowFailure
  }
  
  var isAllFinished: Bool {
    let finishedSize = finishedFlags.filter { return $0 }
    return finishedSize.count == operationsSize
  }
  
  func createGroupOperations(flow: Flow, operationCreator: FlowOperationCreator.Type) -> [FlowOperation] {
    return [FlowOperation]()
  }
  
  func collectOutput(flow: Flow, op: FlowOperation) {
  }
}

public class FlowArrayGroupDispatcher: FlowGroupDispatcher {
  var outputs = [Int: Any]()
  
  override func createGroupOperations(flow: Flow, operationCreator: FlowOperationCreator.Type) -> [FlowOperation] {
    var operations = [FlowOperation]()
    if let dataArray = flow.dataBucket[inputKey] as? [Any] {
      operationsSize = dataArray.count
      for index in 0..<operationsSize {
        let op = operationCreator.create()
        let inputObject = dataArray[index]
        var groupDataBucket = [String: Any]()
        groupDataBucket[op.primaryInputParamKey] = inputObject
        op.groupTag = index
        op.groupDataBucket = groupDataBucket
        operations.append(op)
        finishedFlags.append(false)
      }
    }
    flow.log(message: "[FlowArrayGroupDispatcher] group created: \(operations.count)")
    return operations
  }
  
  override func collectOutput(flow: Flow, op: FlowOperation) {
    let index = op.groupTag as! Int
    if let outputObject = op.groupDataBucket?[op.primaryOutputParamKey] {
      outputs[index] = outputObject
    }
    finishedFlags[index] = true
    if isAllFinished {
      let sortedKeys = outputs.keys.sorted()
      var outputArray = [Any]()
      for key in sortedKeys {
        if let output = outputs[key] {
          outputArray.append(output)
        }
      }
      flow.setData(name: outputKey, value: outputArray)
      flow.log(message: "[FlowArrayGroupDispatcher] all finished. output size: \(outputArray.count)")
    }
  }
}
