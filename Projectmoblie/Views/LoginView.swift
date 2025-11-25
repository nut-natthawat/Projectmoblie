import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    
    // 🔥 เพิ่ม State สำหรับสลับโชว์รหัส
    @State private var isPasswordVisible = false
    
    @State private var errorMessage = ""
    @State private var showError = false
    
    @FocusState private var focusedField: Field?
    @State private var isHovering = false

    var body: some View {
        ZStack {
            AppColors.white.ignoresSafeArea()
            Group {
                Circle()
                    .fill(AppColors.hotPink)
                    .frame(width: 250, height: 250)
                    .offset(x: 150, y: -400)
                    .blur(radius: 100)
                    .opacity(0.5)
                
                Circle()
                    .fill(AppColors.hotPink)
                    .frame(width: 300, height: 300)
                    .offset(x: -100, y: 400) 
                    .blur(radius: 100)
                    .opacity(0.5)
            }
            .allowsHitTesting(false)
            VStack(spacing: 25) {
                Image("Login")
                Text("Sign In")
                    .font( .largeTitle)
                    .bold()
                    .padding(-20)
                Text("Please sign in to continue.")
                    .font(.title3)
                    .bold()
                    .padding(-10)
                
                VStack(spacing: 8) {
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
                            .keyboardType(.emailAddress)
                    }
                    
                    VStack(spacing:8){
                        Text("Password")
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(AppColors.dark)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ZStack(alignment: .trailing) {
                            if isPasswordVisible {
                                TextField("Password", text: $password)
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
                            } else {
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
                            }
                            
                            Button(action: {
                                isPasswordVisible.toggle()
                            }) {
                                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                            .padding(.trailing, 8)
                        }
                    }
                    }
                    
                .padding(.horizontal)
                
                Button(action: {
                    authManager.login(email: email, password: password) { result in
                        switch result {
                        case .success(_):
                            print("Login Success!")
                        case .failure(let error):
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }) {
                    Text("Sign In")
                        .font(.system(size: 20, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.hotPink)
                        .foregroundColor(AppColors.light)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                HStack{
                    Text("Do not have any account?")
                        .bold()
                    NavigationLink(destination: RegisterView()) {
                        Text("Register")
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
    LoginView().environmentObject(AuthManager())
}
