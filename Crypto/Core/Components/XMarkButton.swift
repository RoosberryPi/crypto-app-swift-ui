//
//  XMarkButton.swift
//  Crypto
//
//  Created by Rosa Meijers on 13/06/2023.
//

import SwiftUI

struct XMarkButton: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Button(action: {
            // presentationMode.wrappedValue.dismiss() seems broken
            
            var firstWindow = UIApplication
                .shared
                .connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .last { $0.isKeyWindow }
                
            firstWindow?.rootViewController?.dismiss(animated: true)
        }, label: {
            Image(systemName: "xmark")
                .font(.headline)
        })
    }
}

struct XMarkButton_Previews: PreviewProvider {
    static var previews: some View {
        XMarkButton()
    }
}
