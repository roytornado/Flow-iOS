import Flow

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
