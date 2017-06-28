//
//  main.swift
//  krbpass
//

import Foundation
import GSS

// We need to get console input from the end user for username and passwords
print("Type in your AD account username (5+3 short name): ", terminator:"")
var username = readLine(strippingNewline: true)!
let pwd1 = getpass("Type in your current password: ")
let currentPassword = String.init(cString: pwd1!)
let pwd2 = getpass("Type in your new password: ")
let newPassword1 = String.init(cString: pwd2!)
let pwd3 = getpass("Type the new password for the second time: ")
let newPassword2 = String.init(cString: pwd3!)

// If any of the values are empty, exit program
if(username.isEmpty || currentPassword.isEmpty || newPassword1.isEmpty || newPassword2.isEmpty) {
    print("You cannot supply empty values")
    exit(0)
}
// If new passwords don't match or the user supplied empty username, exit program
if(!(newPassword1 == newPassword2)) {
    print("Your new passwords didn't match")
    exit(0)
}

// Append the username with Company's full identity
username.append("@YOURGSSREALM.COM")

// Create GSS name
let gssName = GSSCreateName(username as CFTypeRef, &__gss_c_nt_user_name_oid_desc, nil)

// Create password dictionary for TGT grant
let pwdValue: Dictionary = [kGSSICPassword:currentPassword]

// Credentials are not needed to change the password. This is here to demonstrate how to create a kerberos identity
// Create Identity for the user (for some reason the only way I could create a valid but null ref is to allocate and deallocate it)
var cred: UnsafeMutablePointer<gss_cred_id_t> = UnsafeMutablePointer.allocate(capacity: 1)
defer {
    cred.deallocate(capacity: 1)
}
var tgtError: Unmanaged<CFError>?

// Try to obtain kerberos credentials
let tgtStatus = gss_aapl_initial_cred(gssName!, &__gss_krb5_mechanism_oid_desc, pwdValue as CFDictionary?, cred, &tgtError)

// Check if there is an error value and if there is, obtain the description and print it
if(tgtStatus > 0) {
    let errorDict = CFErrorCopyUserInfo(tgtError?.takeRetainedValue()) as Dictionary
    print(errorDict.values.first!)
    exit(0)
}

// Create password dictionary for password change
let pwdValues: Dictionary = [kGSSChangePasswordOldPassword:currentPassword, kGSSChangePasswordNewPassword:newPassword1]

var pwdError: Unmanaged<CFError>?

//Change the password
let status = gss_aapl_change_password(gssName!, &__gss_krb5_mechanism_oid_desc, pwdValues as CFDictionary, &pwdError)

// Check if there is an error value and if there is, obtain the description and print it
if(status > 0) {
    let errorDict = CFErrorCopyUserInfo(pwdError?.takeRetainedValue()) as Dictionary
    print(errorDict.values.first!)
    print("You probably tried to change the password for more than once per 24h or your new password format does not comply with some other password policy of your Company")
    exit(0)
}
else {
    print("Your password was changed succesfully!")
}
