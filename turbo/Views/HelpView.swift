//
//  HelpView.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-04.
//

import SwiftUI

struct HelpView: View {
    @State var start = UnitPoint(x: 0, y: -2)
    @State var end = UnitPoint(x: 4, y: 0)
    let colors = [Color.white, Color.white,(Color(red: 90/255, green: 200/255, blue: 190/255))]
    
    init() {
            //Use this if NavigationBarTitle is with Large Font
            UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.black]

            //Use this if NavigationBarTitle is with displayMode = .inline
            UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.black]
    }
    var body : some View{
        ZStack{
            
            LinearGradient(gradient: Gradient(colors: colors), startPoint: start, endPoint: end).ignoresSafeArea()
            VStack{
                ScrollView{
                    Text("Step 1:\nFrom the home screen, tap \"Select Category\" and choose a deck like Family, Friends, Relationships, Icebreakers, Controversial, Random, or Would You Rather.\n\nStep 2:\nSwipe left and right through the questions until you find questions you like.\n\nStep 3:\nIn default categories, tap the \"Generate Question\" button to have Talkaholic's AI create a fresh, unique question based on what you've been playing.\n\nStep 4:\nIf you love a question, tap the bookmark icon in the top right to open \"Save Question\". Choose one or more custom categories (or create a new one) and tap Save.\n\nStep 5:\nTo manage your saved questions, tap \"My Categories\" on the home screen. Open any custom category to review, rename, or remove questions.\n\nStep 6:\nUse any deck with any group of people to spark meaningful conversation!").font(.system(size: 24)).fontWeight(.semibold).padding(30).background(Color.white).cornerRadius(40).shadow(radius: 6).padding(20).foregroundColor(Color.gray)
                }.padding(.top).navigationBarTitle("How to play").edgesIgnoringSafeArea(.bottom)
            }
        }
    }
}

#Preview {
    NavigationStack { HelpView() }
}
