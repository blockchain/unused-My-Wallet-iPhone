//
//  LocalizationConstants.h
//  Blockchain
//
//  Created by Tim Lee on 8/6/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//
#import <Foundation/Foundation.h>

#define BC_STRING_ANY_ADDRESS NSLocalizedString(@"Any Address", nil)
#define BC_STRING_SEND_PAYMENT_FROM NSLocalizedString(@"Send Payment From:", nil)
#define BC_STRING_SEND_PAYMENT_TO NSLocalizedString(@"Send Payment To:", nil)

#define BC_STRING_YOU_MUST_ENTER_DESTINATION_ADDRESS NSLocalizedString(@"You must enter a destination address", nil)

#define BC_STRING_INVALID_TO_BITCOIN_ADDRESS NSLocalizedString(@"Invalid to bitcoin address", nil)
#define BC_STRING_INVALID_SEND_VALUE NSLocalizedString(@"Invalid Send Value", nil)

#define BC_STRING_NO_ACTIVE_BITCOIN_ADDRESSES_AVAILABLE NSLocalizedString(@"You have no active bitcoin addresses available for sending", nil)
#define BC_STRING_ADD_TO_ADDRESS_BOOK NSLocalizedString(@"Add to Address book?", nil)
#define BC_STRING_NO NSLocalizedString(@"No", nil)
#define BC_STRING_YES NSLocalizedString(@"Yes", nil)
#define BC_STRING_PLEASE_WAIT NSLocalizedString(@"Please Wait", nil)
#define BC_STRING_SIGNING_INPUTS NSLocalizedString(@"Signing Inputs", nil)

#define BC_STRING_FINISHED_SIGNING_INPUTS NSLocalizedString(@"Finished Signing Inputs", nil)
#define BC_STRING_SUCCESS NSLocalizedString(@"Success", nil)
#define BC_STRING_PAYMENT_SENT NSLocalizedString(@"Payment Sent!", nil)

#define BC_STRING_CONFIRM_PAYMENT NSLocalizedString(@"Confirm Payment", nil)
#define BC_STRING_ASK_TO_ADD_TO_ADDRESS_BOOK NSLocalizedString(@"Would you like to add the bitcoin address %@ to your address book?", nil)
#define BC_STRING_COPIED_TO_CLIPBOARD NSLocalizedString(@"%@ copied to clipboard", nil)
#define BC_STRING_SIGNING_INPUT NSLocalizedString(@"Signing Input %d", nil)
#define BC_STRING_CONFIRM_PAYMENT_OF NSLocalizedString(@"Confirm payment of %@ (%@) to %@", nil)
#define BC_STRING_SEND_FROM NSLocalizedString(@"Send from...", nil)
#define BC_STRING_SEND_TO NSLocalizedString(@"Send to...", nil)

#define BC_STRING_YOU_MUST_ENTER_A_LABEL NSLocalizedString(@"You must enter a label", nil)
#define BC_STRING_LABEL_MUST_BE_ALPHANUMERIC NSLocalizedString(@"Label must contain letters and numbers only", nil)
#define BC_STRING_UNARCHIVE NSLocalizedString(@"Unarchive", nil)
#define BC_STRING_ARCHIVE NSLocalizedString(@"Archive", nil)
#define BC_STRING_ACTIVE NSLocalizedString(@"Active", nil)
#define BC_STRING_ARCHIVED NSLocalizedString(@"Archived", nil)
#define BC_STRING_NO_LABEL NSLocalizedString(@"No Label", nil)
#define BC_STRING_TRANSACTIONS_COUNT NSLocalizedString(@"%d Transactions", nil)
#define BC_STRING_LOADING_EXTERNAL_PAGE NSLocalizedString(@"Loading External Page", nil)


#define BC_STRING_PASSWORD_MUST_10_CHARACTERS_OR_LONGER NSLocalizedString(@"Password must 10 characters or longer", nil)
#define BC_STRING_PASSWORDS_DO_NOT_MATCH NSLocalizedString(@"Passwords do not match", nil)
#define BC_STRING_PLEASE_PROVIDE_AN_EMAIL_ADDRESS NSLocalizedString(@"Please provide an email address.", nil)
#define BC_STRING_INVALID_EMAIL_ADDRESS NSLocalizedString(@"Invalid email address.", nil)
#define BC_STRING_DID_CREATE_NEW_ACCOUNT_DETAIL NSLocalizedString(@"Before accessing your wallet, please choose a pin number to use to unlock your wallet. It's important you remember this pin as it cannot be reset or changed without first unlocking the app.", nil)
#define BC_STRING_DID_CREATE_NEW_ACCOUNT_TITLE NSLocalizedString(@"Your wallet was successfully created.", nil)



#define BC_STRING_COUNT_MORE NSLocalizedString(@"%d more", nil)
#define BC_STRING_UNCONFIRMED NSLocalizedString(@"Unconfirmed", nil)
#define BC_STRING_COUNT_CONFIRMATIONS NSLocalizedString(@"%d Confirmations", nil)

#define BC_STRING_TRANSACTION_MOVED NSLocalizedString(@"MOVED", nil)
#define BC_STRING_TRANSACTION_RECEIVED NSLocalizedString(@"RECEIVED", nil)
#define BC_STRING_TRANSACTION_SENT NSLocalizedString(@"SENT", nil)

#define BC_STRING_ERROR NSLocalizedString(@"Error", nil)

#define BC_STRING_INFORMATION NSLocalizedString(@"Information", nil)
#define BC_STRING_IMPORTED_PRIVATE_KEY NSLocalizedString(@"Imported Private Key %@", nil)
#define BC_STRING_DECRYPTING_PRIVATE_KEY NSLocalizedString(@"Decrypting Private Key", nil)

#define BC_STRING_UNSUPPORTED_PRIVATE_KEY_FORMAT NSLocalizedString(@"Unsupported Private Key Format", nil)
#define BC_STRING_PARSING_PAIRING_CODE NSLocalizedString(@"Parsing Pairing Code", nil)

#define BC_STRING_OK NSLocalizedString(@"OK", nil)
#define BC_STRING_FAILED_TO_LOAD_WALLET_TITLE NSLocalizedString(@"Failed To Load Wallet", nil)

#define BC_STRING_NO_INTERNET_CONNECTION NSLocalizedString(@"No internet connection.", nil)
#define BC_STRING_TIMED_OUT NSLocalizedString(@"Connection timed out. Please check your internet connection.", nil)
#define BC_STRING_EMPTY_RESPONSE NSLocalizedString(@"Empty response from server.", nil)
#define BC_STRING_INVALID_RESPONSE NSLocalizedString(@"Invalid server response. Please check your internet connection.", nil)

#define BC_STRING_FAILED_TO_LOAD_WALLET_DETAIL NSLocalizedString(@"An error was encountered loading your wallet. You may be offline or Blockchain is experiencing difficulties. Please close the application and try again later or re-pair you device.", nil)
#define BC_STRING_FORGET_WALLET NSLocalizedString(@"Forget Wallet", nil)

#define BC_STRING_CLOSE_APP NSLocalizedString(@"Close App", nil)
#define BC_STRING_PRIVATE_KEY_ENCRYPTED_DESCRIPTION NSLocalizedString(@"The private key you are attempting to import is encrypted. Please enter the password below.", nil)

#define BC_STRING_NO_PASSWORD_ENTERED NSLocalizedString(@"No Password Entered", nil)
#define BC_STRING_SECOND_PASSWORD_INCORRECT NSLocalizedString(@"Second Password Incorrect", nil)

#define BC_STRING_ACTION_REQUIRES_SECOND_PASSWORD NSLocalizedString(@"This action requires the second password for your bitcoin wallet. Please enter it below and press continue.", nil)
#define BC_STRING_INVALID_GUID NSLocalizedString(@"Invalid GUID", nil)

#define BC_STRING_INVALID_SHARED_KEY NSLocalizedString(@"Invalid Shared Key", nil)
#define BC_STRING_ENTER_YOUR_CHARACTER_WALLET_IDENTIFIER NSLocalizedString(@"Please enter your 36 character wallet identifier correctly. It can be found in the welcome email on startup.", nil)
#define BC_STRING_INVALID_IDENTIFIER NSLocalizedString(@"Invalid Identifier", nil)

#define BC_STRING_WALLET_PAIRED_SUCCESSFULLY_DETAIL NSLocalizedString(@"Before accessing your wallet, please choose a pin number to use to unlock your wallet. It's important you remember this pin as it cannot be reset or changed without first unlocking the app.", nil)
#define BC_STRING_WALLET_PAIRED_SUCCESSFULLY_TITLE NSLocalizedString(@"Wallet Paired Successfully.", nil)
#define BC_STRING_ASK_FOR_PRIVATE_KEY_TITLE NSLocalizedString(@"Scan Watch Only Address?", nil)
#define BC_STRING_ASK_FOR_PRIVATE_KEY_DETAIL NSLocalizedString(@"Wallet address %@ has funds available to spend. However the private key needs to be scanned from a paper wallet or QR Code. Would you like to scan the private key now?", nil)
#define BC_STRING_USER_DECLINED NSLocalizedString(@"User Declined", nil)
#define BC_STRING_CHANGE_PIN NSLocalizedString(@"Change PIN", nil)
#define BC_STRING_OPTIONS NSLocalizedString(@"Options", nil)
#define BC_STRING_OPEN_ACCOUNT_SETTINGS NSLocalizedString(@"Open Account Settings, Logout or change your pin below.", nil)
#define BC_STRING_SETTINGS NSLocalizedString(@"Settings", nil)
#define BC_STRING_NEWS_PRICE_CHARTS NSLocalizedString(@"News, Price & Charts", nil)
#define BC_STRING_LOGOUT NSLocalizedString(@"Logout", nil)
#define BC_STRING_REALLY_LOGOUT NSLocalizedString(@"Do you really want to log out?", nil)
#define BC_STRING_WELCOME_BACK NSLocalizedString(@"Welcome Back", nil)
#define BC_STRING_FORGET_DETAILS NSLocalizedString(@"Forget Details", nil)
// #define BC_STRING_WELCOME_TO_BLOCKCHAIN_WALLET NSLocalizedString(@"Welcome to Blockchain Wallet", nil)
#define BC_STRING_WELCOME_INSTRUCTIONS NSLocalizedString(@"If you already have a Blockchain Wallet, choose Pair Device; otherwise, choose Create Wallet.    It's Free! No email required.", nil)
#define BC_STRING_CREATE_WALLET NSLocalizedString(@"Create Wallet", nil)

#define BC_STRING_PAIR_DEVICE NSLocalizedString(@"Pair Device", nil)

#define BC_STRING_WARNING NSLocalizedString(@"Warning!!!", nil)
#define BC_STRING_FORGET_WALLET_DETAILS NSLocalizedString(@"This will erase all wallet data on this device. Please confirm you have your wallet information saved elsewhere otherwise any bitcoins in this wallet will be inaccessible!!", nil)
#define BC_STRING_CANCEL NSLocalizedString(@"Cancel", nil)
#define BC_STRING_HOW_WOULD_YOU_LIKE_TO_PAIR NSLocalizedString(@"How would you like to pair?", nil)
#define BC_STRING_MANUALLY NSLocalizedString(@"Manually", nil)
#define BC_STRING_AUTOMATICALLY NSLocalizedString(@"Automatically", nil)
#define BC_STRING_PIN_VALIDATION_ERROR NSLocalizedString(@"PIN Validation Error", nil)
#define BC_STRING_PLEASE_CHOOSE_ANOTHER_PIN NSLocalizedString(@"Please choose another PIN", nil)

#define BC_STRING_PIN_VALIDATION_ERROR_DETAIL NSLocalizedString(@"An error occured validating your PIN code with the remote server. You may be offline or blockchain may be experiencing difficulties. Would you like retry validation or instead enter your password manually?", nil)
#define BC_STRING_ENTER_PASSWORD NSLocalizedString(@"Enter Password", nil)
#define BC_STRING_PLEASE_ENTER_PIN NSLocalizedString(@"Please enter your PIN", nil)
#define BC_STRING_PLEASE_ENTER_NEW_PIN NSLocalizedString(@"Please enter a new PIN", nil)
#define BC_STRING_CONFIRM_PIN NSLocalizedString(@"Confirm your PIN", nil)
#define BC_STRING_INCORRECT_PIN_RETRY NSLocalizedString(@"Incorrect PIN. Please retry.", nil)
#define RETRY_VALIDATION NSLocalizedString(@"Retry Validation", nil)
#define BC_STRING_SERVER_RETURNED_NULL_STATUS_CODE NSLocalizedString(@"Server Returned Null Status Code", nil)
#define BC_STRING_PIN_VALIDATION_CANNOT_BE_COMPLETED NSLocalizedString(@"PIN Validation cannot be completed. Please enter your wallet password manually.", nil)
#define BC_STRING_PIN_RESPONSE_OBJECT_SUCCESS_LENGTH_0 NSLocalizedString(@"PIN Response Object success length 0", nil)
#define BC_STRING_DECRYPTED_PIN_PASSWORD_LENGTH_0 NSLocalizedString(@"Decrypted PIN Password length 0", nil)
#define BC_STRING_CANNOT_SAVE_PIN_CODE_WHILE NSLocalizedString(@"Cannot save PIN Code while wallet is not initialized or password is null", nil)
#define BC_STRING_INVALID_STATUS_CODE_RETURNED NSLocalizedString(@"Invalid Status Code Returned %@", nil)
#define BC_STRING_PIN_RESPONSE_OBJECT_KEY_OR_VALUE_LENGTH_0 NSLocalizedString(@"PIN Response Object key or value length 0", nil)
#define BC_STRING_PIN_ENCRYPTED_STRING_IS_NIL NSLocalizedString(@"PIN Encrypted String is nil", nil)
#define BC_STRING_PIN_SAVED_SUCCESSFULLY NSLocalizedString(@"PIN Saved Successfully", nil)

#define BC_STRING_PAYMENT_REQUEST_TITLE NSLocalizedString(@"Payment Request", nil)
#define BC_STRING_DEVICE_NO_SMS NSLocalizedString(@"This device does not support SMS.", nil)
#define BC_STRING_DEVICE_NO_EMAIL NSLocalizedString(@"This device does not support email.", nil)
#define BC_STRING_MY_BITCOIN_ADDRESS NSLocalizedString(@"My Bitcoin Address", nil)
#define BC_STRING_PAY_ME_WITH_BITCOIN NSLocalizedString(@"Pay me with bitcoin", nil)
#define BC_STRING_PAYMENT_REQUEST NSLocalizedString(@"Please send payment to bitcoin address. FAQ: (https://blockchain.info/wallet/bitcoin-faq): %@", nil)
#define BC_STRING_PAYMENT_REQUEST_HTML NSLocalizedString(@"Please send payment to bitcoin address (<a href=\"https://blockchain.info/wallet/bitcoin-faq\">help?</a>): %@", nil)
#define BC_STRING_CLOSE NSLocalizedString(@"Close", nil)
#define BC_STRING_BACK NSLocalizedString(@"Back", nil)
#define BC_STRING_NEW_WALLET NSLocalizedString(@"New Wallet", nil)

#define BC_STRING_CREATE_ACCOUNT NSLocalizedString(@"Create Account", nil)
#define BC_STRING_LABEL NSLocalizedString(@"Label", nil)
#define BC_STRING_NEW_WALLET NSLocalizedString(@"New Wallet", nil)
#define BC_STRING_NEW_WALLET NSLocalizedString(@"New Wallet", nil)
