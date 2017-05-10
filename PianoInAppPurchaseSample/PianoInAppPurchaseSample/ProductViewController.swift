import UIKit
import StoreKit

class ProductViewController: UITableViewController {
    
    let observerContext = UnsafeMutableRawPointer(bitPattern: 0)
    let defaultCellId = "defaultId"
    
    let iapService = IAPService.sharedInstance
    var products = [SKProduct]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        addObserver(self, forKeyPath: #keyPath(iapService.products), options: NSKeyValueObservingOptions.new, context: observerContext)
        iapService.loadProducts()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        products = iapService.products
        tableView.reloadData()        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: defaultCellId)
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: defaultCellId)
        }
        
        let product = products[indexPath.row]
        cell!.textLabel?.text = "\(product.localizedTitle) [\(product.price) \(product.priceLocale.currencySymbol ?? "")]"
        cell!.detailTextLabel?.text = products[indexPath.row].localizedDescription
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let product = products[indexPath.row]
        iapService.buyProduct(product: product)
    }
}

