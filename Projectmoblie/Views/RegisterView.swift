import SwiftUI


struct RegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    @FocusState private var focusedField: Field?
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var isHovering = false

    var body: some View {
        ZStack {
//            AppColors.light.ignoresSafeArea()
            AppColors.white.ignoresSafeArea()
            Group {
                Circle()
                    .fill(AppColors.hotPink)
                    .frame(width: 250, height: 250)
                    .offset(x: 150, y: -400) // เลื่อนตำแหน่ง
                    .blur(radius: 100) // ทำให้เบลอ
                    .opacity(0.5) // โปร่งแสง
                
                Circle()
                    .fill(AppColors.hotPink)
                    .frame(width: 300, height: 300)
                    .offset(x: -100, y: 400)
                    .blur(radius: 100)
                    .opacity(0.5)
            }
            .allowsHitTesting(false)
            
            VStack(spacing: 25) {
                Image("Register")
                Text("Register")
                    .font( .largeTitle)
                    .bold()
                    .padding(-20)
                Text("Please register to login.")
                    .font(.title3)
                    .bold()
                    .padding(-10)
                
                VStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2){
                        Text("Username")
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(AppColors.dark)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        TextField("Username", text: $username)
                            .focused($focusedField, equals: .username)
                            .padding(12)
                            .background(Color(hex: "FFFFFF"))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(focusedField == .username ? AppColors.dark : Color(.systemGray), lineWidth: 2)
                            )
                            .foregroundColor(AppColors.dark)
                            .onTapGesture {
                                focusedField = .username
                            }
                    }
                    VStack(alignment: .leading, spacing: 2){
                        Text("Email")
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(AppColors.dark)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        TextField("Email", text: $email)
                            .focused($focusedField, equals: .email)
                            .padding(12)
                            .background(Color(hex: "FFFFFF"))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(focusedField == .email ? AppColors.dark : Color(.systemGray), lineWidth: 2)
                            )
                            .foregroundStyle(AppColors.dark)
                            .onTapGesture{
                                focusedField = .email
                            }
                            .textInputAutocapitalization(.never)
                    }
                    VStack(alignment: .leading, spacing: 2){
                        Text("Password")
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(AppColors.dark)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        SecureField("Password", text: $password)
                            .focused($focusedField, equals: .password)
                            .padding(12)
                            .background(Color(hex: "FFFFFF"))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(focusedField == .password ? AppColors.dark : Color(.systemGray), lineWidth: 2)
                            )
                            .foregroundStyle(AppColors.dark)
                            .onTapGesture{
                                focusedField = .password
                            }
                            .textInputAutocapitalization(.never)
                    }
                }
                .padding(.horizontal)
                
                Button(action: {
                    // เรียกฟังก์ชัน register จาก AuthManager
                    authManager.register(email: email, password: password, username: username) { result in
                        switch result {
                        case .success(_):
                            print("Resgister Success!")
                            // ไม่ต้องทำอะไร เดี๋ยว ContentView จะเปลี่ยนหน้าให้เองเมื่อ currentUser เปลี่ยน
                        case .failure(let error):
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }) {
                    Text("Sign Up")
                        .font(.system(size: 20, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isHovering ? AppColors.babyneonGreen : AppColors.hotPink)
                        .foregroundColor(AppColors.light)
                        .cornerRadius(10)
                        .onHover { hovering in
                            self.isHovering = hovering
                        }
                    
                }
                .padding(.horizontal)
                HStack {
                    Text("Already have an account?")
                        .bold()
                    NavigationLink(destination: LoginView())
                        {
                         Text("Login")
                                .foregroundStyle(AppColors.dark)
                                .underline()
                                .bold()
                        }
                }
                .padding(-20)
                .font(.system(size: 16))
            }
            .padding()
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    RegisterView().environmentObject(AuthManager())
}
