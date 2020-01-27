//
//  LogInProtected.swift
//  ServicesScheduler
//
//  Created by Joseph Van Boxtel on 12/15/19.
//  Copyright © 2019 Joseph Van Boxtel. All rights reserved.
//

import SwiftUI

struct LogInProtected<Content: View>: View {
    @EnvironmentObject var stateMachine: LogInStateMachine
    @EnvironmentObject var presentableStateMachine: PresentableLogInStateMachine
    
    var content: ()->Content
    
    var body: some View {
        _LogInProtected(
            state: presentableStateMachine.state,
            cancel: stateMachine.cancel,
            logIn: stateMachine.presentBrowserLogIn,
            backToLogIn: stateMachine.goBackToLogIn,
            content: content
        )
    }
}

struct DisclaimerOverlay: View {
    var body: some View {
        Text("Services Scheduler is not developed by Planning Center")
            .multilineTextAlignment(.center)
            .padding(.vertical)
            .font(.footnote)
    }
}

func PrimaryButton(action: @escaping ()->(), label: String) -> some View {
    Button(action: action) {
        Text(verbatim: label)
            .padding()
            .background(
                Color(.secondarySystemBackground).cornerRadius(8)
            )
    }.foregroundColor(.servicesGreen).padding()
}

private struct _LogInProtected<Content: View>: View {
    var state: PresentableLogInState
    var cancel: ()->()
    var logIn: ()->()
    var backToLogIn: ()->()
    
    var content: ()->Content
    
    var body: some View {
        Group {
            if state == .welcome || state == .welcomeLoggingIn {
                VStack {
                    Text("Welcome").font(.largeTitle)
                    if state == .welcomeLoggingIn {
                        PrimaryButton(action: cancel, label: "Cancel")
                        HStack {
                            Text("Logging In...")
                            IsVisibleView {
                                LoadingIndicator(isSpinning: $0){
                                    Image(systemName: "questionmark.circle.fill")
                                }
                            }
                        }
                    } else {
                        PrimaryButton(action: logIn, label: "Log In")
                    }
                }
                .frame(maxWidth: .greatestFiniteMagnitude, maxHeight: .greatestFiniteMagnitude)
                .overlay(DisclaimerOverlay(), alignment: .bottom)
                
            } else if state == .loggedIn {
                content()
            } else {
                ErrorView(title: "Failed to Log In", description: state.error!.localizedDescription, actionTitle: "Back to Log In", action: backToLogIn)
            }
        }
    }
}

struct LogInProtected_Previews: PreviewProvider {
    static var previews: some View {
        ForEach([PresentableLogInState.welcome, .welcomeLoggingIn, .loggedIn, .failed(URLError(.cancelled))], id: \.self) {
            _LogInProtected(state: $0, cancel: {}, logIn: {}, backToLogIn: {}) {
                Text("Success")
            }
        }
    }
}
