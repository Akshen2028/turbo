//
//  ContentView.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-10-15.
//

import SwiftUI
import UIKit
import MessageUI
struct HomeView: View {
    @State private var navigateTo = ""
    @State private var isActives = false
    @State private var isActive = false
    @State private var isActive1 = false
    @State var show = false
    @Environment(\.colorScheme) var colorScheme
    @State var sug = false
    @State private var showSheet = false
    @State var result: Result<MFMailComposeResult, Error>? = nil
    var itemsPerRow = 6
    @State var isAnimating = false
    @State var start = UnitPoint(x: 0, y: -2)
    @State var end = UnitPoint(x: 4, y: 0)
    let colors = [Color.white,Color.white,Color(red: 55/255, green: 213/255, blue: 209/255)]
    var body: some View {
        NavigationView(){
            ZStack{
                LinearGradient(gradient: Gradient(colors: colors), startPoint: start, endPoint: end).ignoresSafeArea()
                VStack{
                    ForEach(0..<getNumberOfRows()){i in
                        HStack{
                            ForEach(0..<self.itemsPerRow){j in
                                Image(self.getImage(indexLocation: (i * itemsPerRow) + j))
                                    .resizable().scaledToFit().padding()
                                    .frame(width:UIScreen.main.bounds.width/CGFloat(self.itemsPerRow), height: UIScreen.main.bounds.width/CGFloat(self.itemsPerRow))
                                    .opacity(isAnimating ? 0.5: 0)
                                    .animation(Animation.linear(duration: Double.random(in: 10.0...20.0)).repeatForever(autoreverses: true).delay(Double.random(in:0...5)))
                            }
                        }
                    }
                }.onAppear(){
                    self.isAnimating = true
                }
                VStack{
                    Text("Talkaholic").fontWeight(.bold).foregroundColor(.black).font(.system(size: 38))
                    NavigationLink(destination: CategoryListView()){
                        Text("Select Category").fontWeight(.bold).foregroundColor(.white).padding(20.0).font(.system(size: 20))
                    }
                    .background(Color(red: 55/255, green: 213/255, blue: 209/255))
                    .cornerRadius(80.0)
                    .shadow(radius: 10)
                    
                    Button(action: {
                        self.suggestFeature()
                        sug = false
                    }) {
                        Text("Send Questions").fontWeight(.bold).foregroundColor((Color(red: 55/255, green: 213/255, blue: 209/255))).padding(20.0).font(.system(size: 20))
                    }
                    .background(Color.white)
                    .cornerRadius(80.0)
                    .shadow(radius: 10)
                    .padding(4.0)
                    .sheet(isPresented: $showSheet) {
                        if sug{
                        MailView(result: self.$result, newSubject: "New Feature Suggestion", newMsgBody: "I am enjoying this app, but I want to suggest a new feature!!!\n\nSuggestion:")
                        }else{
                        MailView(result: self.$result, newSubject: "New Question Suggestion", newMsgBody: "I am enjoying this app, but I want to send a new Question!!!\n\nCategory: \n\nQuestion: ")
                        }
                    }
                    Spacer().frame(height:200)
                }
                VStack{
                    Spacer()
                    HStack{
                        NavigationLink(destination: AboutView()){
                            Image(systemName:"info.circle.fill").resizable().scaledToFit().frame(width:40).padding(-7).background(Color.white).padding(13).cornerRadius(20).shadow(radius: 12).foregroundColor(Color(red: 55/255, green: 213/255, blue: 209/255))
                        }
                        NavigationLink(destination: HelpView()){
                            Image(systemName:"questionmark.circle.fill").resizable().scaledToFit().frame(width:40).padding(-7).background(Color(red: 55/255, green: 213/255, blue: 209/255)).padding(13).cornerRadius(20).shadow(radius: 12).foregroundColor(Color.white).padding(.leading, 0)
                        }
                    }
                    Spacer().frame(height: 200)
                }
                
            }
        }.accentColor( .black)
    }
    func getImage(indexLocation:Int) -> String{
        return String(indexLocation % 2)
    }
    
    func getNumberOfRows() -> Int{
        let heightPerItem = UIScreen.main.bounds.width/CGFloat(self.itemsPerRow)
        return Int(UIScreen.main.bounds.height/heightPerItem) + 1
    }
    func suggestFeature() {
        print("Hurray! New Suggestion")
        if MFMailComposeViewController.canSendMail() {
            self.showSheet = true
        } else {
            print("Error sending mail")
            // Alert : Unable to send the mail
        }
    }
}

#Preview {
    HomeView()
}
