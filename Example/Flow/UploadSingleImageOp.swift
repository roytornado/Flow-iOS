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
