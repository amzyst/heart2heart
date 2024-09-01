import SwiftUI

struct ContentView: View {
    @State private var userInput = ""
    @State private var chatDisplay = [Message(text: "Welcome to Heart-to-Heart", isUser: false)]
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            ScrollView {
                ForEach(chatDisplay, id: \.id) { message in
                    HStack {
                        if message.isUser {
                            Spacer()
                        }
                        Text(message.text)
                            .padding()
                            .background(message.isUser ? Color.pink.opacity(0.15) : Color.blue.opacity(0.15))
                            .cornerRadius(20)
                            .foregroundColor(.black)
                            .frame(maxWidth: 250, alignment: message.isUser ? .trailing : .leading)
                        
                        if !message.isUser {
                            Spacer()
                        }
                    }
                    .padding(message.isUser ? .leading : .trailing, 50)
                    .padding(.vertical, 5)
                }
            }
            .padding()

            HStack {
                TextField("Type your message...", text: $userInput, onCommit: {
                    sendMessage()
                })
                .textFieldStyle(PlainTextFieldStyle())
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .foregroundColor(.black)
                
                Button(action: {
                    sendMessage()
                }) {
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        Text("Send")
                            .padding()
                            .background(Color(red: 0.5, green: 0.9, blue: 0.5))
                            .foregroundColor(.black)
                            .cornerRadius(25)
                            .shadow(radius: 3)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .disabled(isLoading)
            }
            .padding()
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
    }

    func sendMessage() {
        guard !userInput.isEmpty else { return }
        chatDisplay.append(Message(text: userInput, isUser: true))
        userInput = ""
        
        isLoading = true
        performChatRequest()
    }

    func performChatRequest() {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // request.addValue("Bearer ", forHTTPHeaderField: "Authorization")
        // request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant."],
                ["role": "user", "content": userInput]
            ],
            "max_tokens": 150
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { isLoading = false }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Error reaching the API: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received"
                }
                return
            }
            
            do {
                if let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = responseJSON["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let botResponse = message["content"] as? String {
                    DispatchQueue.main.async {
                        self.chatDisplay.append(Message(text: botResponse, isUser: false))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "JSON Parsing error: \(error.localizedDescription)"
                }
            }
        }
        task.resume()
    }
}

struct Message {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
