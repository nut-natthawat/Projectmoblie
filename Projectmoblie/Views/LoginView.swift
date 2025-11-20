import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    
    // 🔥 เพิ่ม State สำหรับสลับโชว์รหัส
    @State private var isPasswordVisible = false
    
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        VStack(spacing: 25) {
            // Logo
            Image(systemName: "figure.run.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.orange)
            
            Text("ving di wa")
                .font(.largeTitle)
                .bold()
            
            VStack(spacing: 15) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                
                // 🔥 ส่วนช่อง Password ที่มีปุ่มตา
                ZStack(alignment: .trailing) {
                    if isPasswordVisible {
                        TextField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 8) // ขยับปุ่มเข้ามานิดนึง
                }
            }
            .padding(.horizontal)

            // ปุ่ม Login
            Button(action: {
                authManager.login(email: email, password: password) { result in
                    switch result {
                    case .success(_):
                        print("Login สำเร็จ!")
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }) {
                Text("Login")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            // ปุ่มไปหน้า Register
            NavigationLink(destination: RegisterView()) {
                Text("ยังไม่มีบัญชี? สมัครสมาชิก")
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .alert("เกิดข้อผิดพลาด", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}

#Preview {
    LoginView().environmentObject(AuthManager())
}
