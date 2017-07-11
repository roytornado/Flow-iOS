import Foundation

extension FlowOperationTreeNode {
  func findAllLeaves() -> [FlowOperationTreeNode] {
    var results = [FlowOperationTreeNode]()
    for node in childNodes {
      let leaf = node.findLeaf()
      results.append(leaf)
    }
    return results
  }
  
  func findLeaf() -> FlowOperationTreeNode {
    var current = self
    while current.childNodes.count > 0 {
      current = current.childNodes[0]
    }
    return current
  }
}
