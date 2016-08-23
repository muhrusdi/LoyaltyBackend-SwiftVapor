import Vapor
import Fluent
import VaporMySQL
import VaporMustache
import HTTP

// MARK: - Configuration

let mustache = VaporMustache.Provider(withIncludes: [
    "header" : "Includes/header.mustache",
    "footer" : "Includes/footer.mustache"
])

let preparations: [Preparation.Type] = [Customer.self, Purchase.self, Voucher.self, CustomerSession.self, Config.self]
let providers: [Vapor.Provider.Type] = [VaporMySQL.Provider.self]

let drop = Droplet(preparations: preparations, providers: providers, initializedProviders: [mustache])

// MARK: - Root

drop.get("/") { request in
    return "Hello, Royalty!"
}

// MARK: - Customers

let customers = CustomerController(droplet: drop)
drop.resource("customers", customers)

drop.post("customers/login") { request in
    return try customers.login(request: request)
}

drop.post("customers/logout") { request in
    return try customers.logout(request: request)
}

drop.post("customers", Customer.self, "purchases") { request, customer in
    return try customer.purchases().all().makeResponse()
}

drop.post("customers", Customer.self, "vouchers") { request, customer in
    return try customer.vouchers().all().makeResponse()
}

let customerMiddleware = CustomerMiddleware(droplet: drop)
drop.middleware.append(customerMiddleware)

// MARK: - Purchases

let purchases = PurchaseController(droplet: drop)
drop.resource("purchases", purchases)

let purchaseMiddleware = PurchaseMiddleware(droplet: drop)
drop.middleware.append(purchaseMiddleware)

// MARK: - Vouchers

let vouchers = VoucherController(droplet: drop)
drop.resource("vouchers", vouchers)

let voucherMiddleware = VoucherMiddleware(droplet: drop)
drop.middleware.append(voucherMiddleware)

// MARK: - Config

let configController = ConfigController(droplet: drop)

drop.get("config") { request in
    guard let config = try Config.all().first
    else {
        throw Abort.serverError
    }
    
    return try configController.show(request: request, item: config)
}

drop.put("config") { request in
    guard let config = try Config.all().first
    else {
        throw Abort.serverError
    }
    
    return try configController.update(request: request, item: config)
}

// MARK: - Serve

let port = drop.config["app", "port"].int ?? 80

drop.serve()