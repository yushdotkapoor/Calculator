import UIKit

/// Simple view controller which shows a privacy message.
class PrivacyProtectionViewController: UITableViewController {
    
    init() {
        super.init(style: .grouped)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
    }
}
