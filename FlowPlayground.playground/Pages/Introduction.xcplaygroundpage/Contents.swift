//: Playground - noun: a place where people can play

import UIKit
import XCPlayground

class DemoDelayOperation: FlowOperation {
  init(name: String) {
    super.init()
    self.name = name
  }
  
  override func mainLogic() {
    print("Running \(name!)")
    sleep(1)
  }
}


let flow = Flow()
flow.add(operation: DemoDelayOperation(name: "Step1"))
flow.add(operation: DemoDelayOperation(name: "Step2.A"), case: FlowCase(key: "flag", value: "A"))
flow.add(operation: DemoDelayOperation(name: "Step2.B"), case: FlowCase(key: "flag", value: "B"))
flow.start()

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true
