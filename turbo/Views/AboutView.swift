//
//  AboutView.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-04.
//

import SwiftUI

struct AboutView: View {
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
                    Text("Description:\n\nTalkaholic is a conversation game designed to help families, friends, couples, and new groups go deeper, faster. Choose from curated decks like Family, Friends, Relationships, Icebreakers, Controversial, Random, and Would You Rather.\n\nSwipe through hand-picked questions or tap \"Generate Question\" in a category to have our AI create a brand‑new prompt tailored to your vibe. When you find questions you love, save them into your own custom categories so you can revisit, organize, and refine them over time.\n\nUse Talkaholic one-on-one, on dates, at parties, or in team settings any time you want to spark real conversation instead of small talk.\n\nContact Us\n\nInstagram: @talk_aholic\nEmail: connect@talkaholic.ca\nWebsite: talkaholic.ca").font(.system(size: 20)).fontWeight(.semibold).padding(30).background(Color.white).cornerRadius(40).shadow(radius: 6).padding(20).foregroundColor(Color.gray)
                }.padding(.top).navigationBarTitle("About").edgesIgnoringSafeArea(.bottom)
            }
        }
    }
}

#Preview {
    NavigationStack { AboutView() }
}
