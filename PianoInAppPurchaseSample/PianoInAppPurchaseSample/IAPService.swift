import Foundation
import StoreKit

public class IAPService: NSObject {
    
    public static let sharedInstance = IAPService()
    
    // product id's registered in app store
    fileprivate let productIds: Set<String> = [
        "io.piano.in.app.purchase.product1", // valid
        "io.piano.in.app.purchase.product2", // valid
        "io.piano.in.app.purchase.product3", // valid
        "io.piano.in.app.purchase.product4", // valid
        "io.piano.in.app.purchase.product5", // invalid
        "io.piano.in.app.purchase.product6", // invalid
    ];
    
    dynamic public fileprivate(set) var products = [SKProduct]()
    
    public override init() {
        super.init()
        
        SKPaymentQueue.default().add(self)
    }
    
    // Loads list of products for current app from appstore
    public func loadProducts() {
        let request = SKProductsRequest(productIdentifiers: productIds)
        request.delegate = self;
        
        print("Product request ...")
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        request.start()
    }
    
    // Initiates product buying
    public func buyProduct(product: SKProduct) {
        let payment = SKMutablePayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    // Get app's receipt
    public func getReceipt() -> String {
        var receiptData: NSData?
        do {
            receiptData = try NSData(contentsOf: Bundle.main.appStoreReceiptURL!, options: NSData.ReadingOptions.alwaysMapped)
        }
        catch {
            print("Error get receipt: " + error.localizedDescription)
        }
        
        let receiptString = receiptData?.base64EncodedString(options: [])
        return receiptString ?? ""
    }
    
    
    // Sends receipt to piano.io for verification and providing access to resource for user
    public func createExternalVerificationTermConversion() {
        let receipt = getReceipt()
        
        var formData = [String: String]()
        formData["aid"] = Environment.aid
        formData["term_id"] = Environment.termId
        formData["user_token"] = Environment.userToken
        formData["user_provider"] = Environment.userProvider
        formData["fields"] = "{\"receiptData\": \"\(receipt)\"}"
        
        var paramArray = [String] ()
        for param in formData {
            paramArray.append("\(param.key)=\(param.value.escape())")
        }
        
        let requestBody = paramArray.joined(separator: "&").data(using: String.Encoding.utf8)
        var request = URLRequest(url: URL(string: Environment.endpoint)!)
        request.httpMethod = "POST"
        request.httpBody = requestBody
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        
        let urlSession = URLSession(configuration: URLSessionConfiguration.default)
        let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
            print("Response from piano.io:")
            
            if error != nil {
                print(error?.localizedDescription ?? "")
            }
            
            if data != nil {
                print(String(data: data!, encoding: String.Encoding.utf8) ?? "")
            }
        }
        
        print("Send to piano.io:")
        dataTask.resume()
    }
}

// Product request handler
extension IAPService: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        print("Invalid product id's: \(response.invalidProductIdentifiers.sorted())")
        for p in response.products {
            print("Product: \(p.productIdentifier) \(p.localizedTitle)(\(p.localizedDescription))[\(p.price) \(p.priceLocale.currencySymbol ?? "")])")
        }
        
        self.products = response.products
    }
}

// Payment queue observer
extension IAPService: SKPaymentTransactionObserver {
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for t in transactions {
            print("transaction id: \(t.transactionIdentifier ?? "n/a") [\(t.transactionState.description)]")
            if (t.error != nil) {
                print("errors: \(t.error!.localizedDescription)")
            }
            
            switch t.transactionState {
            case .restored, .purchased:
                createExternalVerificationTermConversion()
                queue.finishTransaction(t)
            case .failed:
                queue.finishTransaction(t)
            default: break
            }
        }
    }
}

// Debug description
extension SKPaymentTransactionState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .deferred: return "deferred"
        case .failed: return "failed"
        case .purchased: return "purchased"
        case .purchasing: return "purchasing"
        case .restored: return "restored"
        }
    }
}

// String escaping
extension String {
    public func escape() -> String {
        let generalDelimitersToEncode = ":#[]@"
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: generalDelimitersToEncode + subDelimitersToEncode)
        
        return self.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? self
    }
}


