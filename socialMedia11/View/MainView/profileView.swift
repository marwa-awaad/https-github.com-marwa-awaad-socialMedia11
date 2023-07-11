//
//  profileView.swift
//  socialMedia11
//
//  Created by marwa awwad mohamed awwad on 11.07.2023.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

struct profileView: View {
    //profile data
    @State private var myProfile: User?
    @AppStorage("login_status") var logStatus : Bool = false
    @State var errorMessage: String = ""
    @State var showError: Bool = false
    @State var isLoading: Bool = false
    var body: some View {
        
        NavigationStack{
            
            VStack{
                
                if let myProfile {
                    ReusableProfileContents (user:  myProfile )
                        .refreshable {
                            self.myProfile = nil
                            //to refresh user data
                            await fetchUserData()
                        }
                }else{
                    ProgressView()
                }
            }
            
            
            .navigationTitle( "My profile ")
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing ){
                    Menu{
                        //2 actions
                        //first to logout
                        //second to delete account
                        Button("logout",action:  logOutUser)
                        Button("delete account ",role: .destructive,action: deleteAccount)
                        
                        
                        
                    }label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.init(degrees: 90))
                        .tint(.black  )}
                    .scaleEffect(0.8  )}
                
            }
            .overlay {
                LoginView (show : $isLoading ){
                    
                    
                    
                }
                .alert(errorMessage, isPresented: $showError){
                    
                }
                .task {//this modifieer is like on apear
                    //so fetching for first time only
                    if  myProfile != nil {return}
                    
                    //initial fetch
                    await fetchUserData()
                }
            }
            //fetching user data
        }
        func fetchUserData()async{
            guard let userUID = Auth.auth().currentUser?.uid  else{return}
           guard let user = try? await  Firestore.firestore().collection("User").document(userUID).getDocument(as:User.self)
            else{return}
            
            await MainActor.run(body:{
                myProfile = user
        
            })
        }
                //logging user out
                func logOutUser(){
                    try? Auth.auth().signOut()
                    logStatus = false
                }
                //deleting the account
                
                func deleteAccount(){
                    isLoading = true
                    Task{
                        do{
                            guard let userUID  = Auth.auth().currentUser?.uid else {return}
                            //first delete profile photo from storage
                            let refrence = Storage.storage().reference().child("profile_picture").child(userUID)
                            try await await refrence.delete()
                            //delete fire store user document
                            try Firestore.firestore().collection("User").document().userUID.delete()
                            //deleting auth account  and setting log status to false
                            try Auth.auth().currentUser?.delete()
                            logStatus = false
                        }catch{
                            await SSLSetError(error )
                        }
                        
                    }
                
            }
            //setting error
            func serError(_ error:  Error)async{
                //UI must be run on main thread
                await MainActor.run(body: {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError.toggle()
                })
            }
        
        
    }
//struct profileView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView
//    }
//}
