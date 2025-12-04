//
//  MailViewModel.swift
//  turbo
//
//  Created by Akshen Jasikumar on 2025-12-04.
//

import SwiftUI
import MessageUI
import Combine

@MainActor
class MailViewModel: ObservableObject {

    // Controls whether sheet is shown
    @Published var isShowingMailComposer = false

    // Stores result from the mail composer
    @Published var mailResult: Result<MFMailComposeResult, Error>? = nil

    // Subject and body of the email
    @Published var subject: String = ""
    @Published var body: String = ""

    // MARK: - Actions

    func prepareForQuestion() {
        subject = "New Question Suggestion"
        body = """
        I am enjoying this app, but I want to send a new Question!!!

        Category:

        Question:
        """
        presentMail()
    }

    func prepareForFeatureSuggestion() {
        subject = "New Feature Suggestion"
        body = """
        I am enjoying this app, but I want to suggest a new feature!!!

        Suggestion:
        """
        presentMail()
    }

    // MARK: - Presentation Logic

    private func presentMail() {
        if MFMailComposeViewController.canSendMail() {
            isShowingMailComposer = true
        } else {
            print("Error: This device cannot send mail.")
        }
    }
}
