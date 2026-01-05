import SwiftUI

struct NoPasscodeView: View {
    let mode: Mode

    var body: some View {
            VStack(spacing: 32) {
                Text(mode.description)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 48)
    }
}

extension NoPasscodeView {
    enum Mode {
        case noPasscode
        case cannotCheckPasscode

        var description: String {
            switch self {
            case .noPasscode: return "This app requires that phone has the passcode (screen lock) enabled.\n\nYou may enable it in iOS settings.\n\nPlease note that when you disabled the PIN on the OS level the security measures in safe storage of your phonе made the previously stored data invalid. You will need to Restore your wallet keys to get back to your wallet."
            case .cannotCheckPasscode: return "Unable to check the state of passcode (screen lock). Please restart the application."
            }
        }
    }
}

