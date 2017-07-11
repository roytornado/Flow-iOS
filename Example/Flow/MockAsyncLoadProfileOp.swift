import Flow

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
