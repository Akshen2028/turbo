//
//  MailView.swift
//  Talkaholic
//
//  Created by Akshen Jasikumar on 2021-01-07.
//

import SwiftUI
import MessageUI

struct MailView: UIViewControllerRepresentable {

    @Environment(\.presentationMode) private var presentation
    @Binding var result: Result<MFMailComposeResult, Error>?

    let subject: String
    let body: String

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var presentation: PresentationMode
        @Binding var result: Result<MFMailComposeResult, Error>?

        init(presentation: Binding<PresentationMode>,
             result: Binding<Result<MFMailComposeResult, Error>?>) {
            _presentation = presentation
            _result = result
        }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            defer { presentation.dismiss() }

            if let error = error {
                self.result = .failure(error)
                return
            }

            self.result = .success(result)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            presentation: presentation,
            result: $result
        )
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(["contact@talkaholic.ca"])
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
}
