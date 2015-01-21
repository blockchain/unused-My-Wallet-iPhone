var MyWalletPhone = {};
var pendingTransactions = {};

window.onerror = function(errorMsg, url, lineNumber) {
    device.execute("jsUncaughtException:url:lineNumber:", [errorMsg, url, lineNumber]);
}

$(document).ajaxStart(function() {
    // Disconnect WS when we send another request to the server - this was leading to crashes
    webSocketDisconnect();
    device.execute('ajaxStart');
}).ajaxStop(function() {
    device.execute('ajaxStop');
    // Re-connent WS again when the request is finished
    simpleWebSocketConnect();
});

console.log = function(message) {
    device.execute("log:", [message]);
}

APP_NAME = 'javascript_iphone_app';
APP_VERSION = '0.1 BETA';

// Set the API code for the iOS Wallet for the server calls
MyWallet.setAPICode('35e77459-723f-48b0-8c9e-6e9e8f54fbd3');

$(document).ready(function() {
    MyWallet.logout = function() {}
});

MyWallet.getWebWorkerLoadPrefix = function() {
    return '';
}


// Register for JS event handlers and forward to Obj-C handlers

MyWallet.addEventListener(function (event, obj) {
    var eventsWithObjCHandlers = ["did_decrypt", "did_fail_set_guid", "did_multiaddr", "did_set_latest_block", "error_restoring_wallet", "hd_wallets_does_not_exist", "hw_wallet_balance_updated", "logging_out", "on_add_private_key", "on_backup_wallet_error", "on_backup_wallet_success", "on_block", "on_error_adding_private_key", "on_error_creating_new_account", "on_error_pin_code_get_empty_response", "on_error_pin_code_get_error", "on_error_pin_code_get_invalid_response", "on_error_pin_code_get_timeout", "on_error_pin_code_put_error", "on_pin_code_get_response", "on_pin_code_put_response", "on_tx", "on_wallet_decrypt_finish", "on_wallet_decrypt_start", "ws_on_close ", "ws_on_open ", "on_backup_wallet_start"];

    // TODO this will change again
    if (event == 'msg') {

    if (obj.type == 'info' && obj.platform == 'iOS') {
        device.execute('setLoadingText:', [obj.message])
    }

    else if (obj.type == 'error') {
        // TODO The server currently returns 500s if there are no free outputs - ignore it until server handles this differently
        if (obj.message == 'No free outputs to spend')
            return

        // Some messages are JSON objects and the error message is in the map
        try {
            var messageJSON = JSON.parse(obj.message);
            if (messageJSON && messageJSON.initial_error) {
                device.execute('makeNotice:id:message:', [''+obj.type, ''+obj.code, ''+messageJSON.initial_error])
                return
            }
        } catch (e) {}

        device.execute('makeNotice:id:message:', [''+obj.type, ''+obj.code, ''+obj.message])
    }

    else if (obj.type == 'success') {
        device.execute('makeNotice:id:message:', [''+obj.type, ''+obj.code, ''+obj.message])
    }

    return

    }

    if (eventsWithObjCHandlers.indexOf(event) == -1)
         return;

    // Obj-C part of handling events (calls function of event name in Wallet.m)
    if (obj) {
        event += ':';
    }

    device.execute(event, [obj]);
});

MyWallet.monitor(function (obj) {
    console.log('Monitor event. Type: ' + (obj.type ? obj.type : 'null') +
                ' Code: ' + (obj.code ? obj.code : 'null') +
                ' Message: ' + (obj.message ? obj.message : 'null'))

    // TODO depcrecated - change in own calls
    if (obj.type == 'loadingText') {
        device.execute('setLoadingText:', [obj.message])
    }

    else if (obj.type == 'error') {
        // TODO The server currently returns 500s if there are no free outputs - ignore it until server handles this differently
        if (obj.message == 'No free outputs to spend')
            return

        device.execute('makeNotice:id:message:', [''+obj.type, ''+obj.code, ''+obj.message])
    }

    else if (obj.type == 'success') {
        device.execute('makeNotice:id:message:', [''+obj.type, ''+obj.code, ''+obj.message])
    }
});


// My Wallet phone functions

MyWalletPhone.cancelTxSigning = function() {
    for (var key in pendingTransactions) {
        pendingTransactions[key].cancel();
    }
}

MyWalletPhone.upgradeToHDWallet = function() {
    MyWallet.upgradeToHDWallet(MyWalletPhone.getSecondPassword,
                               function () { console.log('Created Account') },
                               function (msg) { console.log('Failed to create Account: ' + msg) });
    
    // Then get the history (and balances) from the server
    MyWallet.getHistoryAndParseMultiAddressJSON();
}

MyWalletPhone.createAccount = function(label) {
    var success = function () {
        console.log('Created new account')
    }
    
    var error = function () {
        console.log('Error creating new account')
    }
    
    MyWallet.createAccount(label, MyWalletPhone.getSecondPassword, success, error)
}

MyWalletPhone.fetchWalletJson = function(user_guid, shared_key, resend_code, inputedPassword, twoFACode, success, needs_two_factor_code, wrong_two_factor_code, other_error) {
    var success = function() {
        MyWallet.getHistoryAndParseMultiAddressJSON();
        device.execute('did_decrypt')
    }
    var other_error = function() { }
    MyWallet.fetchWalletJson(user_guid, shared_key, resend_code, inputedPassword, twoFACode, success, needs_two_factor_code, wrong_two_factor_code, null, other_error)
}

MyWalletPhone.quickSendFromAddressToAddress = function(from, to, valueString) {
    var id = ''+Math.round(Math.random()*100000);
    
    var success = function() {
        device.execute('tx_on_success:', [id]);
    }
    
    var error = function(error) {
        device.execute('tx_on_error:error:', [id, ''+error.message]);
    }
    
    var value = Bitcoin.BigInteger.valueOf(valueString);
    
    var fee = null;
    var note = null;
    
    MyWallet.sendFromLegacyAddressToAddress(from, to, value, fee, note, success, error, MyWalletPhone.getSecondPassword);
    
    return id;
}

MyWalletPhone.quickSendFromAddressToAccount = function(from, to, valueString) {
    var id = ''+Math.round(Math.random()*100000);
    
    var success = function() {
        device.execute('tx_on_success:', [id]);
    }
    
    var error = function(error) {
        device.execute('tx_on_error:error:', [id, ''+error.message]);
    }
    
    var value = Bitcoin.BigInteger.valueOf(valueString);
    
    var fee = null;
    var note = null;
    
    MyWallet.sendFromLegacyAddressToAccount(from, to, value, fee, note, success, error, MyWalletPhone.getSecondPassword);
    
    return id;
}

MyWalletPhone.quickSendFromAccountToAddress = function(from, to, valueString) {
    var id = ''+Math.round(Math.random()*100000);
        
    var success = function() {
        device.execute('tx_on_success:', [id]);
    }
    
    var error = function(error) {
        device.execute('tx_on_error:error:', [id, ''+error.message]);
    }
    
    var value = parseInt(valueString);
    
    var fee = MyWallet.recommendedTransactionFeeForAccount(from, value);
    var note = null;
    
    MyWallet.sendBitcoinsForAccount(from, to, value, fee, note, success, error, MyWalletPhone.getSecondPassword);
    
    return id;
}

MyWalletPhone.quickSendFromAccountToAccount = function(from, to, valueString) {
    var id = ''+Math.round(Math.random()*100000);
    
    var success = function() {
        device.execute('tx_on_success:', [id]);
    }
    
    var error = function(error) {
        device.execute('tx_on_error:error:', [id, ''+error.message]);
    }
    
    var value = parseInt(valueString);
    
    var fee = MyWallet.recommendedTransactionFeeForAccount(from, value);
    var note = null;
    
    // TODO temporary to set/unset second password
//    var _success = function() {
//        console.log('Success: Second password saved')
//    }
//    
//    var _error = function(e) {
//        console.log('Error: Second password not saved: ' + e)
//    }
//    
//    var _password = "test"
//    MyWallet.setSecondPassword(_password, _success, _error);
    
    MyWallet.sendToAccount(from, to, value, fee, note, success, error, MyWalletPhone.getSecondPassword);
    
    return id;
}

MyWalletPhone.apiGetPINValue = function(key, pin) {
    MyWallet.sendMonitorEvent({type: "loadingText", message: "Retrieving PIN Code", code: 0});

    $.ajax({
        type: "POST",
        url: BlockchainAPI.getRootURL() + 'pin-store',
        timeout: 20000,
        dataType: 'json',
        data: {
           format: 'json',
           method: 'get',
           pin : pin,
           key : key
       },
       success: function (responseObject) {
           device.execute('on_pin_code_get_response:', [responseObject]);
       },
       error: function (res) {
          // Connection timed out
           if (res && res.statusText == "timeout") {
                device.execute('on_error_pin_code_get_timeout');
           }
           // Empty server response
           else if (!res || !res.responseText || res.responseText.length == 0) {
                device.execute('on_error_pin_code_get_empty_response');
           } else {
                try {
                    var responseObject = $.parseJSON(res.responseText);
           
                    if (!responseObject) {
                        throw 'Response Object nil';
                    }
           
                    device.execute('on_pin_code_get_response:', [responseObject]);
                } catch (e) {
                    // Invalid server response
                    device.execute('on_error_pin_code_get_invalid_response');
                }
           }
       }
    });
};

MyWalletPhone.pinServerPutKeyOnPinServerServer = function(key, value, pin) {
    MyWallet.sendMonitorEvent({type: "loadingText", message: "Saving PIN Code", code: 0});
    
    $.ajax({
        type: "POST",
        url: BlockchainAPI.getRootURL() + 'pin-store',
        timeout: 30000,
        data: {
            format: 'plain',
            method: 'put',
            value : value,
            pin : pin,
            key : key
        },
        success: function (responseObject) {
           responseObject.key = key;
           responseObject.value = value;
           
           device.execute('on_pin_code_put_response:', [responseObject])
        },
        error: function (res) {
            if (!res || !res.responseText || res.responseText.length == 0) {
                device.execute('on_error_pin_code_put_error:', ['Unknown Error']);
           } else {
                try {
                    var responseObject = $.parseJSON(res.responseText);
           
                    responseObject.key = key;
                    responseObject.value = value;

                    device.execute('on_pin_code_put_response:', [responseObject])
                } catch (e) {
                    device.execute('on_error_pin_code_put_error:', [res.responseText]);
                }
           }
        }
    });
}

MyWalletPhone.newAccount = function(password, email) {
    MyWallet.createNewWallet(email, password, null, null, function(guid, sharedKey, password) {
                                 device.execute('on_create_new_account:sharedKey:password:', [guid, sharedKey, password]);
                             }, function (e) {
                                 device.execute('on_error_creating_new_account:', [''+e]);
                             });
}

MyWalletPhone.parsePairingCode = function (raw_code) {
    
    var success = function (pairing_code) {
        device.execute("didParsePairingCode:", [pairing_code]);
    }
    
    var error = function (e) {
        device.execute("errorParsingPairingCode:", [e]);
    }
    
    try {
        if (raw_code == null || raw_code.length == 0) {
            throw "Invalid Pairing QR Code";
        }
        
        if (raw_code[0] != '1') {
            throw "Invalid Pairing Version Code " + raw_code[0];
        }
        
        var components = raw_code.split("|");
        
        if (components.length < 3) {
            throw "Invalid Pairing QR Code. Not enough components.";
        }
        
        var guid = components[1];
        if (guid.length != 36) {
            throw "Invalid Pairing QR Code. GUID wrong length.";
        }
        
        var encrypted_data = components[2];
        
        MyWallet.sendMonitorEvent({type: "loadingText", message: "Decrypting Pairing Code", code: 0});
        
        $.ajax({
               type: "POST",
               url: BlockchainAPI.getRootURL() + 'wallet',
               timeout: 60000,
               data: {
               format: 'plain',
               method: 'pairing-encryption-password',
               guid: guid
               },
               success: function (encryption_phrase) {
               try {
               
               // Pairing code PBKDF2 iterations is set to 10 in My Wallet
               var pairing_code_pbkdf2_iterations = 10;
               var decrypted = MyWallet.decrypt(encrypted_data, encryption_phrase, pairing_code_pbkdf2_iterations, function (decrypted) {
                                                return decrypted != null;
                                                }, function () {
                                                error('Decryption Error');
                                                });
               
               if (decrypted != null) {
               var components2 = decrypted.split("|");
               
               success({
                       version: raw_code[0],
                       guid: guid,
                       sharedKey: components2[0],
                       password: CryptoJS.enc.Hex.parse(components2[1]).toString(CryptoJS.enc.Utf8)
                       });
               } else {
               error('Decryption Error');
               }
               } catch(e) {
               error(''+e);
               }
               },
               error: function (res) {
               error('Pairing Code Server Error');
               }
               });
    } catch (e) {
        error(''+e);
    }
}

MyWalletPhone.addAddressBookEntry = function(bitcoinAddress, label) {
    MyWallet.addAddressBookEntry(bitcoinAddress, label);
    
    MyWallet.backupWallet();
}

MyWalletPhone.detectPrivateKeyFormat = function(privateKeyString) {
    try {
        return MyWallet.detectPrivateKeyFormat(privateKeyString);
    } catch(e) {
        return null;
    }
}

MyWalletPhone.hasEncryptedWalletData = function() {
    var data = MyWallet.getEncryptedWalletData();
    
    return data && data.length > 0;
}

MyWalletPhone.getWsReadyState = function() {
    if (!ws) return -1;

    return ws.readyState;
}

MyWalletPhone.get_wallet_and_history = function() {
    MyWallet.getWallet(function() {
        MyWallet.get_history()
    })
}

MyWalletPhone.getMultiAddrResponse = function() {
    var obj = {};

    obj.transactions = MyWallet.getTransactions();
    obj.total_received = MyWallet.getTotalReceived();
    obj.total_sent = MyWallet.getTotalSent();
    obj.final_balance = MyWallet.getFinalBalance();
    obj.n_transactions = MyWallet.getNTransactions();
    obj.addresses = MyWallet.getAllLegacyAddresses();

    obj.symbol_local = symbol_local;
    obj.symbol_btc = symbol_btc;

    return obj;
}

MyWalletPhone.addPrivateKey = function(privateKeyString) {
    var success = function(address) {
        console.log('Add private key success')
        
        device.execute('on_add_private_key:', [address])
    }
    var error = function(e) {
        console.log('Add private key Error')
        
        device.execute('on_error_adding_private_key:', [''+e]);
    }
    
    MyWallet.importPrivateKey(privateKeyString, MyWalletPhone.getSecondPassword, MyWalletPhone.getPrivateKeyPassword, success, error)
}

// Shared functions

function simpleWebSocketConnect() {
    console.log('Connecting websocket...');
    
    if (!window.WebSocket) {
        console.log('No websocket support in JS runtime');
        return;
    }
    
    if (!MyWallet.getIsInitialized()) {
        console.log('Wallet is not initialized yet');
        return;
    }
    
    if (ws && reconnectInterval) {
        console.log('Websocket already exists. Connection status: ' + ws.readyState);
        return;
    }
    
    // This should never really happen - try to recover gracefully
    if (ws) {
        console.log('Websocket already exists but no reconnectInverval. Connection status: ' + ws.readyState);
        webSocketDisconnect();
    }
    
    MyWallet.connectWebSocket();
}

function webSocketDisconnect() {
    console.log('Disconnecting websocket...');
    
    if (!window.WebSocket) {
        console.log('No websocket support in JS runtime');
        return;
    }
    
    if (!MyWallet.getIsInitialized()) {
        console.log('Wallet is not initialized yet');
        return;
    }
    
    if (reconnectInterval) {
        clearInterval(reconnectInterval);
        reconnectInterval = null;
    }
    else {
        console.log('No reconnectInterval');
    }
    
    if (!ws) {
        console.log('No websocket object');
        return;
    }
    
    ws.close();
    
    ws = null;
}


// Overrides

MyWalletPhone.getPrivateKeyPassword = function(callback) {
    // Due to the way the JSBridge handles calls with success/error callbacks, we need a first argument that can be ignored
    device.execute("getPrivateKeyPassword:", ["discard"], function(pw) {
        callback(pw,
                 function () {
                     console.log('BIP38 private key import: password incorrect');
                     device.execute('makeNotice:id:message:', ['error', '', 'Incorrect Passphrase'])
                 });
    }, function(msg) { console.log('Error' + msg) });
}

MyWalletPhone.getSecondPassword = function(callback) {
    // Due to the way the JSBridge handles calls with success/error callbacks, we need a first argument that can be ignored
    device.execute("getSecondPassword:", ["discard"], function(pw) {
        callback(pw,
                function () { console.log('Second password correct') },
                function () { console.log('Second password incorrect') })
        }, function(msg) { console.log('Error' + msg) });
}

ImportExport.Crypto_scrypt = function(passwd, salt, N, r, p, dkLen, callback) {
    if(typeof(passwd) !== 'string') {
        passwd = passwd.toJSON().data;
    }
    
    if(typeof(salt) !== 'string') {
        salt = salt.toJSON().data;
    }
    
    device.execute('crypto_scrypt:salt:n:r:p:dkLen:', [passwd, salt, N, r, p, dkLen], function(buffer) {
        var bytes = new Bitcoin.Buffer.Buffer(buffer, 'hex');
                   
        callback(bytes);
    }, function(e) {
        error(''+e);
    });
}

MyStore.get_old = MyStore.get;
MyStore.get = function(key, callback) {
    // Disallow fetching of the guid
    if (key == 'guid') {
        callback();
        return;
    }
    
    MyStore.get_old(key, callback);
}

// TODO what should this value be?
MyWallet.getNTransactionsPerPage = function() {
    return 50;
}
