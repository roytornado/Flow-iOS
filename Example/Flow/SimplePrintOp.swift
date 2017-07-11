import Flow

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
