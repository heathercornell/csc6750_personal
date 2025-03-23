import SwiftUI

// Transaction and Enum for TransactionType
struct Transaction: Identifiable, Codable {
    let id = UUID()
    let type: TransactionType
    let description: String
    let amount: Double
}

enum TransactionType: String, Codable {
    case sent = "Sent"
    case received = "Received"
    case group = "Group"
    case receipt = "Receipt"
    case request = "Request"  // New case for requesting money

    var iconName: String {
        switch self {
        case .sent: return "arrow.up.circle"
        case .received: return "arrow.down.circle"
        case .group: return "person.3"
        case .receipt: return "doc.text"
        case .request: return "arrow.right.circle"  // Icon for request
        }
    }

    var iconColor: Color {
        switch self {
        case .sent: return .red
        case .received: return .green
        case .group: return .blue
        case .receipt: return .yellow
        case .request: return .orange  // Color for request
        }
    }
}

class AppData: ObservableObject {
    @Published var balance: Double = 100.0
    @Published var transactions: [Transaction] = []
    @Published var lastReceiptTotal: Double = 0.0
    @Published var groups: [Group] = [Group(name: "Group 1", members: ["Alice", "Bob"]),
                                       Group(name: "Group 2", members: ["Charlie"])] // Placeholder for group names and members

    func saveBalance() {
        if let encoded = try? JSONEncoder().encode(balance) {
            UserDefaults.standard.set(encoded, forKey: "balance")
        }
    }

    func loadBalance() {
        if let savedData = UserDefaults.standard.data(forKey: "balance"),
           let decoded = try? JSONDecoder().decode(Double.self, from: savedData) {
            balance = decoded
        }
    }

    func saveTransactions() {
        if let encoded = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(encoded, forKey: "transactions")
        }
    }

    func loadTransactions() {
        if let savedData = UserDefaults.standard.data(forKey: "transactions"),
           let decoded = try? JSONDecoder().decode([Transaction].self, from: savedData) {
            transactions = decoded
        }
    }

    func saveGroups() {
        if let encoded = try? JSONEncoder().encode(groups) {
            UserDefaults.standard.set(encoded, forKey: "groups")
        }
    }

    func loadGroups() {
        if let savedData = UserDefaults.standard.data(forKey: "groups"),
           let decoded = try? JSONDecoder().decode([Group].self, from: savedData) {
            groups = decoded
        }
    }
}

struct Group: Identifiable, Codable {
    let id = UUID()
    var name: String
    var members: [String]
}

struct ContentView: View {
    var body: some View {
        TabView {
            TransactionsView()
                .tabItem {
                    Label("Transactions", systemImage: "dollarsign.circle")
                }
            GroupsView()
                .tabItem {
                    Label("Groups", systemImage: "person.3.fill")
                }
            ChatbotView()
                .tabItem {
                    Label("Chatbot", systemImage: "message.fill")
                }
            ReceiptScannerView()
                .tabItem {
                    Label("Scan Receipt", systemImage: "doc.text.magnifyingglass")
                }
        }
        .accentColor(.white)
    }
}

struct TransactionsView: View {
    @EnvironmentObject var appData: AppData
    @State private var amount: String = ""
    @State private var paymentDescription: String = ""

    var body: some View {
        VStack {
            Text("Balance: $\(String(format: "%.2f", appData.balance))")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
                .padding()

            TextField("Enter amount", text: $amount)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
                .foregroundColor(.white)

            TextField("Enter description", text: $paymentDescription)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
                .foregroundColor(.white)

            Button("Send Payment") {
                sendPayment()
            }
            .disabled(amount.isEmpty || Double(amount) == nil || Double(amount)! <= 0 || Double(amount)! > appData.balance)
            .padding()
            .background(amount.isEmpty || Double(amount) == nil || Double(amount)! <= 0 || Double(amount)! > appData.balance ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            List(appData.transactions) { transaction in
                TransactionRow(transaction: transaction)
            }
            .background(Color.black)
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }

    func sendPayment() {
        if let value = Double(amount), value > 0, value <= appData.balance {
            appData.balance -= value
            let transaction = Transaction(type: .sent, description: paymentDescription.isEmpty ? "Payment sent" : paymentDescription, amount: value)
            appData.transactions.insert(transaction, at: 0)
            appData.saveTransactions()  // Save after a transaction
            amount = ""
            paymentDescription = ""
        }
    }
}

struct TransactionRow: View {
    var transaction: Transaction

    var body: some View {
        HStack {
            Image(systemName: transaction.type.iconName)
                .foregroundColor(transaction.type.iconColor)
                .padding()

            VStack(alignment: .leading) {
                Text(transaction.description)
                    .foregroundColor(.white)
                    .bold()
                Text("$\(String(format: "%.2f", transaction.amount))")
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}

// Groups Tab
struct GroupsView: View {
    @EnvironmentObject var appData: AppData
    @State private var newGroupName: String = ""
    @State private var newMemberName: String = ""
    @State private var selectedGroupIndex: Int? = nil
    @State private var requestAmount: String = ""  // Input for requested amount

    var body: some View {
        VStack {
            Text("Manage Groups")
                .font(.largeTitle)
                .foregroundColor(.white)
                .padding()

            List {
                ForEach(appData.groups.indices, id: \.self) { index in
                    VStack(alignment: .leading) {
                        Text(appData.groups[index].name)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Members: \(appData.groups[index].members.joined(separator: ", "))")
                            .foregroundColor(.white)
                            .font(.subheadline)
                            .padding(.bottom, 5)

                        Button("Edit Group") {
                            selectedGroupIndex = index
                        }
                        .padding(5)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)

                        // Button to request money from the group
                        // Inside the GroupsView struct
                        Button("Request Money from Group") {
                            if let amount = Double(requestAmount), amount > 0 {
                                requestMoneyFromGroup(groupIndex: index, amount: amount)
                            }
                        }

                        .padding(5)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                }
            }

            // Add Group
            TextField("New Group Name", text: $newGroupName)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
                .foregroundColor(.white)

            Button("Create Group") {
                createGroup()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            // Edit Group
            if let index = selectedGroupIndex {
                TextField("New Member Name", text: $newMemberName)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .foregroundColor(.white)

                Button("Add Member to Group") {
                    addMemberToGroup(index: index)
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)

                // Request money input field and button
                TextField("Request Amount", text: $requestAmount)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .foregroundColor(.white)

                Button("Request Money") {
                    if let amount = Double(requestAmount), amount > 0 {
                        requestMoneyFromGroup(groupIndex: index, amount: amount)
                    }
                }
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .background(Color.blue)
        .edgesIgnoringSafeArea(.all)
    }

    func createGroup() {
        if !newGroupName.isEmpty {
            appData.groups.append(Group(name: newGroupName, members: []))
            newGroupName = ""
            appData.saveGroups()
        }
    }

    func addMemberToGroup(index: Int) {
        if !newMemberName.isEmpty {
            appData.groups[index].members.append(newMemberName)
            newMemberName = ""
            appData.saveGroups()
        }
    }

    func requestMoneyFromGroup(groupIndex: Int, amount: Double) {
        let group = appData.groups[groupIndex]

        // Calculate the total requested amount based on how much to ask from each member
        let totalRequestedAmount = amount / Double(group.members.count)

        // Loop through each member and create a "Request" transaction
        for member in group.members {
            let transaction = Transaction(
                type: .request,
                description: "Request from \(member)",
                amount: totalRequestedAmount
            )
            appData.transactions.insert(transaction, at: 0)
        }

        // Subtract the total requested amount from the balance (if necessary)
        appData.balance -= totalRequestedAmount * Double(group.members.count)

        // Save the transactions and balance after processing
        appData.saveTransactions()
        appData.saveBalance()  // If you need to save the balance separately
    }


}

// Chatbot Tab
struct ChatbotView: View {
    @State private var userMessage: String = ""
    @State private var chatbotResponse: String = "Hello! How can I help you?"

    var body: some View {
        VStack {
            Text("Chatbot")
                .font(.largeTitle)
                .foregroundColor(.white)
                .padding()

            ScrollView {
                Text(chatbotResponse)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.gray.opacity(0.5))
                    .cornerRadius(10)
                    .padding()

                TextField("Type your message...", text: $userMessage)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .foregroundColor(.white)

                Button("Send") {
                    sendMessage()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .background(Color.gray)
        .edgesIgnoringSafeArea(.all)
    }

    func sendMessage() {
        // For now, just echo back the message with a basic response
        chatbotResponse = "You said: \(userMessage)\nChatbot: How can I assist you further?"
        userMessage = ""
    }
}

// Receipt Scanner Tab
struct ReceiptScannerView: View {
    @EnvironmentObject var appData: AppData
    @State private var scannedAmount: String = ""
    
    var body: some View {
        VStack {
            Text("Scan Receipt")
                .font(.largeTitle)
                .foregroundColor(.white)
                .padding()

            Text("Scanned amount: $\(scannedAmount)")
                .foregroundColor(.white)
                .padding()

            Button("Simulate Receipt Scan") {
                scanReceipt()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .background(Color.orange)
        .edgesIgnoringSafeArea(.all)
    }

    func scanReceipt() {
        // Simulate a receipt scan by deducting a random value
        let randomAmount = Double.random(in: 5...100)
        appData.balance -= randomAmount
        appData.transactions.insert(Transaction(type: .receipt, description: "Receipt scanned", amount: randomAmount), at: 0)
        scannedAmount = String(format: "%.2f", randomAmount)
    }
}

@main
struct VenmoAIApp: App {
    @StateObject var appData = AppData()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appData)
                .preferredColorScheme(.dark)
                .onAppear {
                    appData.loadTransactions()  // Load transactions on app start
                    appData.loadGroups()       // Load groups on app start
                }
        }
    }
}
