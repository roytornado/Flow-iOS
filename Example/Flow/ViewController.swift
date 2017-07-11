import UIKit
import Flow

class ViewController: UIViewController {
  
  @IBOutlet weak var summaryTextView: UITextView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
  }
  
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
  
  func showAlert(message: String) {
    let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    present(alert, animated: true, completion: nil)
  }
  
  @IBAction func simpleChainedFlow() {
    Flow()
      .add(operation: SimplePrintOp(message: "hello world"))
      .add(operation: SimplePrintOp(message: "good bye"))
      .setWillStartBlock(block: commonWillStartBlock())
      .setDidFinishBlock(block: commonDidFinishBlock())
      .start()
  }
  
  @IBAction func demoLoginSuccess() {
    Flow()
      .setDataBucket(dataBucket: ["email": "test@gmail.com", "password": "123456"])
      .add(operation: MockAsyncLoginOp())
      .add(operation: MockAsyncLoadProfileOp())
      .setWillStartBlock(block: commonWillStartBlock())
      .setDidFinishBlock(block: commonDidFinishBlock() {
        flow in
        if flow.isSuccess {
          self.showAlert(message: "Login Success for \(flow.dataBucket["email"]!)")
        } else {
          self.showAlert(message: "Login Fail")
        }
      })
      .start()
  }
  
  @IBAction func demoLoginFlowWithMissingData() {
    // MockAsyncLoginSuccessOp requires email but not exist in data bucket
    Flow()
      .setDataBucket(dataBucket: ["email_address": "test@gmail.com", "password": "123456"])
      .add(operation: MockAsyncLoginOp())
      .add(operation: MockAsyncLoadProfileOp())
      .setWillStartBlock(block: commonWillStartBlock())
      .setDidFinishBlock(block: commonDidFinishBlock())
      .start()
  }
  
  @IBAction func demoLoginFlowWithIncorrectDataType() {
    // MockAsyncLoginSuccessOp requires password with String type but it's Int in data bucket
    Flow()
      .setDataBucket(dataBucket: ["email": "test@gmail.com", "password": 123456])
      .add(operation: MockAsyncLoginOp())
      .add(operation: MockAsyncLoadProfileOp())
      .setWillStartBlock(block: commonWillStartBlock())
      .setDidFinishBlock(block: commonDidFinishBlock())
      .start()
  }
  
  @IBAction func demoLoginFail() {
    Flow()
      .setDataBucket(dataBucket: ["email": "test@gmail.com", "password": "654321"])
      .add(operation: MockAsyncLoginOp())
      .add(operation: MockAsyncLoadProfileOp())
      .setWillStartBlock(block: commonWillStartBlock())
      .setDidFinishBlock(block: commonDidFinishBlock())
      .start()
  }
  
  @IBAction func demoDispatcher() {
    Flow()
      .setDataBucket(dataBucket: ["images": ["a", "b", "c", "d", 1]])
      //.setDataBucket(dataBucket: ["images": [1]])
      .addGrouped(operationCreator: UploadSingleImageOp.self, dispatcher: FlowArrayGroupDispatcher(inputKey: "images", outputKey: "imageURLs", maxConcurrentOperationCount: 3, allowFailure: false))
      .setWillStartBlock(block: commonWillStartBlock())
      .setDidFinishBlock(block: commonDidFinishBlock())
      .start()
  }
  
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
  
}

