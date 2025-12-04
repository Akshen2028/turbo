//
//  HelpView.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-04.
//

import SwiftUI

struct HelpView: View {
    init() {
            //Use this if NavigationBarTitle is with Large Font
            UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.black]

            //Use this if NavigationBarTitle is with displayMode = .inline
            UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.black]
    }
    @State var start = UnitPoint(x: 0, y: -2)
    @State var end = UnitPoint(x: 4, y: 0)
    let colors = [Color.white, Color.white,(Color(red: 90/255, green: 200/255, blue: 190/255))]
    var body : some View{
        ZStack{
            
            LinearGradient(gradient: Gradient(colors: colors), startPoint: start, endPoint: end).ignoresSafeArea()
            VStack{
                ScrollView{
                    Text("Step 1:\nClick \"Select Category\".\n\nStep 2:\nChoose from a variety of catagories to start your conversation.\n\nStep 3:\nFeel free to switch between catagories, as your spot will be saved.\n\nStep 4:\nTo shuffle up the questions and restart, simply go back to the home screen and click \"Select Category\" again.\n\nStep 5:\nRemember, the questions are ABOUT the category you choose, so you can use any category with any group of people!\n\nStep 6:\nClick \"Send Questions\" on the home page to send in your own questions for the opportunity to get them uploaded on Talkaholic!").font(.system(size: 24)).fontWeight(.semibold).padding(30).background(Color.white).cornerRadius(40).shadow(radius: 6).padding(20).foregroundColor(Color.gray)
                }.padding(.top).navigationBarTitle("How to play").edgesIgnoringSafeArea(.bottom)
            }
        }
    }
}

#Preview {
    NavigationStack { HelpView() }
}
