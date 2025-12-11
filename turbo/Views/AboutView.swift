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
                    Text("Description:\n\nTalkaholic is the best way to bring families, friends, or even strangers together through conversation. It comes with various categories filled with questions ranging from simple icebreakers to thought provoking questions that allow individuals to get to know each other on a deeper level. Use it one-on-one or in a group setting to uplift a party, date, meeting, or any plain old conversation.\n\nCredits:\n\nFamily icon by Freepik, from www.flaticon.com\nFriends icon by Freepik, from www.flaticon.com\nDices icon by Freepik, from www.flaticon.com\nRose icon by Freepik, from www.flaticon.com\nIce icon by Freepik, from www.flaticon.com\nBalance icon by Freepik, from www.flaticon.com\n\nContact Us\n\nInstagram: @talk_aholic\nEmail: connect@talkaholic.ca\nWebsite: talkaholic.ca").font(.system(size: 20)).fontWeight(.semibold).padding(30).background(Color.white).cornerRadius(40).shadow(radius: 6).padding(20).foregroundColor(Color.gray)
                }.padding(.top).navigationBarTitle("About").edgesIgnoringSafeArea(.bottom)
            }
        }
    }
}

#Preview {
    NavigationStack { AboutView() }
}
