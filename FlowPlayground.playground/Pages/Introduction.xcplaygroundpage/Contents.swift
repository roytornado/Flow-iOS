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

class UploadImageOperation: FlowOperation {
  override func mainLogic() {
    guard let imageData = getData(name: "imageData") as? String else { return }
    print("Uploading Image")
    sleep(1)
    setData(name: "imageUrl", value: "https://1234")
  }
}

class CreateChatroomWithImageOperation: FlowOperation {
  var isNetworkFinished = false
  
  override func mainLogic() {
    guard let imageUrl = getData(name: "imageUrl") as? String else { return }
    
    DispatchQueue.global().async {
      print("Creating Chatroom")
      sleep(2)
      print("Created Chatroom")
      self.finishAsyncTask()
    }
    waitUntilFinished()
  }
  
  override var isFinished: Bool {
    return isNetworkFinished
  }
  
  func finishAsyncTask() {
    willChangeValue(forKey: "isFinished")
    isNetworkFinished = true
    didChangeValue(forKey: "isFinished")
  }
}


Flow()
  .setDataBucket(dataBucket: ["imageData": "ABCD"])
  .add(operation: DemoDelayOperation(name: "Step1"))
  .add(operation: UploadImageOperation())
  .add(operation: CreateChatroomWithImageOperation())
  //.add(operation: DemoDelayOperation(name: "Step2.A"), case: FlowCase(key: "flag", value: "A"))
  //.add(operation: DemoDelayOperation(name: "Step2.B"), case: FlowCase(key: "flag", value: "B"))
  .start()

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true
