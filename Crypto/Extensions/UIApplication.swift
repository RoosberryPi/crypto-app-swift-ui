//
//  UIApplication.swift
//  Crypto
//
//  Created by Rosa Meijers on 06/06/2023.
//

import Foundation
import SwiftUI

extension UIApplication {
    
    func endEditing() {
        // will dismiss the keyboard
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
}
