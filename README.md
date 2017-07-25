# Flow

[![Version](https://img.shields.io/cocoapods/v/Flow.svg?style=flat)](http://cocoapods.org/pods/Flow)
[![License](https://img.shields.io/cocoapods/l/Flow.svg?style=flat)](http://cocoapods.org/pods/Flow)
[![Platform](https://img.shields.io/cocoapods/p/Flow.svg?style=flat)](http://cocoapods.org/pods/Flow)

## What's Flow
Flow is an utility/ design pattern that help developers to write simple and readable code.
There are two main concerns:
`Flow of operations and Flow of data`

By using Flow, we should able to achieve the followings:
- Logics / operations can be reused easily
- The logic flows are readable by anyone (including the code reviewers)
- Each line of code is meaningfully and avoid ambiguous keywords
- No more callback hell for complicated async operations
- Debuggable both at development and production stage

Flow is referencing Composite pattern (https://en.wikipedia.org/wiki/Composite_pattern) and
Chain-of-responsibility pattern (which including Command pattern) (https://en.wikipedia.org/wiki/Chain-of-responsibility_pattern)

So, we encapsulate operations as objects which can be chained using tree structures. Each operation is independent but able to be used with another one if the data required by the operations exist.

Here is an example for simple usage:
```swift
@IBAction func simpleChainedFlow() {
    Flow()
      .add(operation: SimplePrintOp(message: "hello world"))
      .add(operation: SimplePrintOp(message: "good bye"))
      .setWillStartBlock(block: commonWillStartBlock())
      .setDidFinishBlock(block: commonDidFinishBlock())
      .start()
  }
```
In these 5 lines of code, we can know that two operations will be executed in serial and able to do something before and after the operations.

## Naming
To make the logic readable, it is important to make the operation's name meaningfully. It is developer's responsibility to make a good name. Also, the name also determine the degree of reusable of code.
e.g. If you create an operation named: `SimplePrintOp`, it should contain only the code to print the message associated with it. You should NOT do anything out of the context of the name. Such as sending the message to server / write to file.

Also, all operations made for Flow should share a common suffix (e.g. Op) so all developers can know that there are operations that ready for reuse.

## Grouped Operations
You can run a batch of operations using `FlowArrayGroupDispatcher`.
```swift
Flow()
      .setDataBucket(dataBucket: ["images": ["a", "b", "c", "d"]])
      .addGrouped(operationCreator: UploadSingleImageOp.self, dispatcher: FlowArrayGroupDispatcher(inputKey: "images", outputKey: "imageURLs", maxConcurrentOperationCount: 3, allowFailure: false))
      .start()
```
FlowArrayGroupDispatcher will dispatcher the targeted array in the data bucket to created operations and pass them the required data and collect them afterwards.

```swift
import Flow_iOS
class UploadSingleImageOp: FlowOperation, FlowOperationCreator {
  
  static func create() -> FlowOperation {
    return UploadSingleImageOp()
  }
  
  override var primaryInputParamKey: String { return "targetImageForUpload" }
  override var primaryOutputParamKey: String { return "uploadedImageUrl" }
  
  override func mainLogic() {
    guard let image: String = getData(name: primaryInputParamKey) else { return }
    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
      self.log(message: "simulation of upload single image callback")
      self.setData(name: self.primaryOutputParamKey, value: "url_of_" + image)
      self.finishSuccessfully()
    }
    startWithAsynchronous()
  }
}

```
For the above example, FlowArrayGroupDispatcher will create a group of UploadSingleImageOp based on the array size of `images` in data bucket. As UploadSingleImageOp declares `targetImageForUpload` as it's input key and `uploadedImageUrl` as it's output key. FlowArrayGroupDispatcher will create temporary data bucket for each UploadSingleImageOp and contains `targetImageForUpload` inside. If the operation is succeed, FlowArrayGroupDispatcher will collect the object keyed with `uploadedImageUrl` and put into the result array `imageURLs`.

In such design, UploadSingleImageOp can be `reused as single operation or grouped operation`.

You can also set the `maxConcurrentOperationCount (optional, default = 3)` to control whether the operations are executed on one by one or in batch.
If `allowFailure (optional, default = false)` is set to true, the Flow will continue to run even some / all operations in the group are failed. Therefore, the output array may be shorter than the input array or even empty.

## Cases
Flow allow simple cases handling. For example:
```swift
@IBAction func demoCases() {
    Flow()
      .setDataBucket(dataBucket: ["images": ["a", "b", "c", "d", 1], "target": "A"])
      .add(operation: SimplePrintOp(message: "Step1"))
      .add(operation: SimplePrintOp(message: "Step2A1"), flowCase: FlowCase(key: "target", value: "A"))
      .add(operation: SimplePrintOp(message: "Step2A2"))
      .add(operation: SimplePrintOp(message: "Step2B1"), flowCase: FlowCase(key: "target", value: "B"))
      .add(operation: SimplePrintOp(message: "Step2B2"))
      .combine()
      .add(operation: SimplePrintOp(message: "Step3"))
      .setWillStartBlock(block: commonWillStartBlock())
      .setDidFinishBlock(block: commonDidFinishBlock())
      .start()
  }
```
After `Step1` is finished, the Flow will run `Step2A1` branch or `Step2B1` branch depend on the value of `target` in data bucket. And `combine` is used to combine all cases back to a single node `Step3`.

To make the blueprint readable, `nested case is NOT supported`.
Also, the type of case value must be `String`.

## Data Handling
```swift
import Flow_iOS

class MockAsyncLoginOp: FlowOperation {
  override func mainLogic() {
    guard let email: String = getData(name: "email") else { return }
    guard let password: String = getData(name: "password") else { return }
    
    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
      self.log(message: "simulation of login callback")
      if email == "test@gmail.com" && password == "123456" {
        let mockAccessToken = "sdaftadagasg"
        self.setData(name: "accessToken", value: mockAccessToken)
        self.finishSuccessfully()
      } else {
        let error = NSError(domain: "No such account", code: 404, userInfo: nil)
        self.finishWithError(error: error)
      }
    }
    startWithAsynchronous()
  }
}
```
In MockAsyncLoginOp in the example, it require two input data from data bucket (`email` and `password`). The Flow will check if `the data exist` and if `the data type is correct` (i.e. they must be `String` for this case). If no data is found with correct type, the operation is marked as failure and the Flow will stop.
You can request any type you want. For example, you have a class named "LoginData" in your project.
```swift
guard let loginData: LoginData = getData(name: "loginData") else { return }
```

## Making your Operations
Making operation is easy:
1) Pick a `good name`
2) Inherit `FlowOperation`
3) Put your logic inside `mainLogic`
4) For synchronized operation: call `finishSuccessfully` or `finishWithError` based on the result
5) For asynchronized operation: call `startWithAsynchronous` at the end of `mainLogic` after starting your async call
6) use `log` to record your debug logs
7) extends `FlowOperationCreator` to make the operation to use in `Group` And override `primaryInputParamKey` and `primaryOutputParamKey`

Some examples:
```swift
class SimplePrintOp: FlowOperation {
  var message: String!
  
  init(message: String) {
    self.message = message
  }
  
  override func mainLogic() {
    log(message: message)
    finishSuccessfully()
  }
}

class MockAsyncLoadProfileOp: FlowOperation {
  override func mainLogic() {
    guard let accessToken: String = getData(name: "accessToken") else { return }
    
    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
      self.log(message: "simulation of success load profile callback")
      self.setData(name: "profileRefreshDate", value: Date())
      self.finishSuccessfully()
    }
    startWithAsynchronous()
  }
}

class UploadSingleImageOp: FlowOperation, FlowOperationCreator {
  
  static func create() -> FlowOperation {
    return UploadSingleImageOp()
  }
  
  override var primaryInputParamKey: String { return "targetImageForUpload" }
  override var primaryOutputParamKey: String { return "uploadedImageUrl" }
  
  override func mainLogic() {
    guard let image: String = getData(name: primaryInputParamKey) else { return }
    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
      self.log(message: "simulation of upload single image callback")
      self.setData(name: self.primaryOutputParamKey, value: "url_of_" + image)
      self.finishSuccessfully()
    }
    startWithAsynchronous()
  }
}

```
## Callbacks
You can set `WillStartBlock` and `DidFinishBlock` to get notified before or after the Flow run.
They are called in `main thread` so you can do your UI changes.
With the Flow instance in the block, you can get `dataBucket: [String: Any]`, `isSuccess: Bool` and `error: Error?` and do your handling.

It's recommended to make common handling blocks which can further simplify your blueprint.
```swift
  func commonWillStartBlock(block: FlowWillStartBlock? = nil) -> FlowWillStartBlock {
    let result: FlowWillStartBlock = {
      flow in
      block?(flow)
      self.summaryTextView.text = "Flow Starting..."
    }
    return result
  }
  
  func commonDidFinishBlock(block: FlowDidFinishBlock? = nil) -> FlowDidFinishBlock {
    let result: FlowDidFinishBlock = {
      flow in
      block?(flow)
      self.summaryTextView.text = flow.generateSummary()
    }
    return result
  }

```


## Logging
This my most favourite feature when making Flow. It's always hard for developer to trace the console log as there are too many unwanted logs in the console. Even worse in a serious of async operations.
Flow will capture all the logs you sent within the opertions and generate a summary for you at the end.
Call `flow.generateSummary()` in the finish block.

For example:
```
====== Flow Summary ======
4:17:18 PM [DataBucket] start with:
password: 123456
email: test@gmail.com
4:17:18 PM [MockAsyncLoginOp] WillStart
4:17:19 PM [MockAsyncLoginOp] simulation of login callback
4:17:19 PM [DataBucket] add for accessToken: sdaftadagasg
4:17:19 PM [MockAsyncLoginOp] DidFinish: successfully
4:17:19 PM [MockAsyncLoadProfileOp] WillStart
4:17:20 PM [MockAsyncLoadProfileOp] simulation of success load profile callback
4:17:20 PM [DataBucket] add for profileRefreshDate: 2017-07-13 08:17:20 +0000
4:17:20 PM [MockAsyncLoadProfileOp] DidFinish: successfully
4:17:20 PM [DataBucket] end with:
profileRefreshDate: 2017-07-13 08:17:20 +0000
email: test@gmail.com
accessToken: sdaftadagasg
password: 123456
Flow isSuccess: true
======    Ending    ======

====== Flow Summary ======
4:17:06 PM [DataBucket] start with:
password: 123456
email_address: test@gmail.com
4:17:06 PM [MockAsyncLoginOp] WillStart
4:17:06 PM [MockAsyncLoginOp] DidFinish: withInsufficientInputData: can't find <email> in data bucket
4:17:06 PM [DataBucket] end with:
password: 123456
email_address: test@gmail.com
Flow isSuccess: false
======    Ending    ======
```
You can trace the data changes, how the operations run in one place. You can send the summary string to your server if needed.

## Why not RxSwift?
Surely RXsSwift is much more powerful in some aspects.
BUT I think it's always good if we can make our code: `Simple and Human readable`
With `Flow`, even code reviewers and non-programmer can understand your logic in the blueprint.

## Requirements
Swift 3.2
iOS 8.0

## Installation

Flow is available through [CocoaPods](http://cocoapods.org):
```ruby
pod "Flow-iOS"
```

Import:
```swift
import Flow_iOS
```

## Author

Roy Ng, roytornado@gmail.com @ Redso, https://www.redso.com.hk/

Linkedin: https://www.linkedin.com/in/roy-ng-19427735/

## License

Flow is available under the MIT license. See the LICENSE file for more info.
