APP_NAME = 'javascript_iphone_app';
APP_VERSION = '3.0';
API_CODE = '35e77459-723f-48b0-8c9e-6e9e8f54fbd3';
// Don't use minified JS files when loading web worker scripts
min = false;

// Set the API code for the iOS Wallet for the server calls
MyWallet.setAPICode(API_CODE);

var MyWalletPhone = {};
var pendingTransactions = {};

window.onerror = function(errorMsg, url, lineNumber) {
    device.execute("jsUncaughtException:url:lineNumber:", [errorMsg, url, lineNumber]);
};

$(document).ajaxStart(function() {
    // Disconnect WS when we send another request to the server - this was leading to crashes
    webSocketDisconnect();
}).ajaxStop(function() {
    // Re-connect WS again when the request is finished
    simpleWebSocketConnect();
});

console.log = function(message) {
    device.execute("log:", [message]);
};

$(document).ready(function() {
    MyWallet.logout = function() {}
});


// Register for JS event handlers and forward to Obj-C handlers

MyWallet.addEventListener(function (event, obj) {
    var eventsWithObjCHandlers = ["did_fail_set_guid", "did_multiaddr", "did_set_latest_block", "error_restoring_wallet", "hd_wallet_balance_updated", "logging_out", "on_backup_wallet_start", "on_backup_wallet_error", "on_backup_wallet_success", "on_block", "on_tx", "ws_on_close", "ws_on_open", "hd_wallet_set", "did_load_wallet"];

    if (event == 'msg') {
        if (obj.type == 'error') {
            if (obj.message != "For Improved security add an email address to your account.") {
                // Cancel busy view in case any error comes in - except for add email, that's handled differently in makeNotice
                device.execute('loading_stop');
            }

            // Some messages are JSON objects and the error message is in the map
            try {
                var messageJSON = JSON.parse(obj.message);
                if (messageJSON && messageJSON.initial_error) {
                    device.execute('makeNotice:id:message:', [''+obj.type, ''+obj.code, ''+messageJSON.initial_error]);
                    return;
                }
            } catch (e) {}

            device.execute('makeNotice:id:message:', [''+obj.type, ''+obj.code, ''+obj.message]);
        }

        else if (obj.type == 'success') {
            device.execute('makeNotice:id:message:', [''+obj.type, ''+obj.code, ''+obj.message]);
        }

        return;
    }

    if (eventsWithObjCHandlers.indexOf(event) == -1) {
        return;
    }

    // Obj-C part of handling events (calls function of event name in Wallet.m)
    if (obj) {
        event += ':';
    }

    device.execute(event, [obj]);
});


// My Wallet phone functions

MyWalletPhone.cancelTxSigning = function() {
    for (var key in pendingTransactions) {
        pendingTransactions[key].cancel();
    }
}

MyWalletPhone.upgradeToHDWallet = function() {
    var success = function () {
        console.log('Upgraded legacy wallet to HD wallet');

        MyWallet.getHistoryAndParseMultiAddressJSON();
        device.execute('loading_stop');
    };

    var error = function (e) {
        console.log('Error upgrading legacy wallet to HD wallet: ' + e);
        device.execute('loading_stop');
    };

    device.execute('loading_start_upgrade_to_hd');

    MyWallet.upgradeToHDWallet(MyWalletPhone.getSecondPassword(success, error), success, error);
};

MyWalletPhone.createAccount = function(label) {
    var success = function () {
        console.log('Created new account');

        device.execute('loading_stop');
    };

    var error = function () {
        console.log('Error creating new account');

        device.execute('loading_stop');
    };

    MyWallet.createAccount(label, MyWalletPhone.getSecondPassword(success, error), success, error);
};

MyWalletPhone.setPbkdf2Iterations = function(iterations) {
    var success = function () {
        console.log('Updated PBKDF2 iterations');
    };

    var error = function () {
        console.log('Error updating PBKDF2 iterations');
    };

    MyWallet.setPbkdf2Iterations(iterations, success, error, MyWalletPhone.getSecondPassword(success, error));
};

MyWalletPhone.fetchWalletJson = function(user_guid, shared_key, resend_code, inputedPassword, twoFACode, success, needs_two_factor_code, wrong_two_factor_code, other_error) {
    // Timing
    var t0 = new Date().getTime(), t1;
    
    var logTime = function(name) {
        t1 = new Date().getTime();
        
        console.log('----------');
        console.log('Execution time ' + name + ': ' + (t1 - t0) + ' milliseconds.')
        console.log('----------');
        
        t0 = t1;
    };
    
    var fetch_success = function() {
        logTime('download');
        
        device.execute('loading_start_decrypt_wallet');
    };
    
    var decrypt_success = function() {
        logTime('decrypt');
        
        device.execute('did_decrypt');
        
        device.execute('loading_start_build_wallet');
    };
    
    var build_hd_success = function() {
        logTime('build HD wallet');
        
        device.execute('loading_start_multiaddr');
    };
    
    var history_success = function() {
        logTime('get history');
        
        device.execute('loading_stop');
        
        device.execute('did_load_wallet');
        
        BlockchainAPI.get_balances(MyWallet.getLegacyArchivedAddresses(), function(result) {}, function(error) {});
    };
    
    var success = function() {
        MyWallet.getHistoryAndParseMultiAddressJSON(history_success);
    };
    
    var other_error = function(e) {
        console.log('fetchWalletJson: other error: ' + e);
        device.execute('loading_stop');
    };
    
    var needs_two_factor_code = function(type) {
        console.log('fetchWalletJson: needs 2fa of type: ' + MyWallet.get2FATypeString());
        device.execute('loading_stop');
        device.execute('on_fetch_needs_two_factor_code');
    };
    
    device.execute('loading_start_download_wallet');
    
    MyWallet.fetchWalletJson(user_guid, shared_key, resend_code, inputedPassword, twoFACode, success, needs_two_factor_code, wrong_two_factor_code, null, other_error, fetch_success, decrypt_success, build_hd_success);
};

MyWalletPhone.quickSendFromAddressToAddress = function(from, to, valueString) {
    var id = ''+Math.round(Math.random()*100000);

    var listener = {
        on_start : function() {
            device.execute('tx_on_start:', [id]);
        },
        on_begin_signing : function() {
            device.execute('tx_on_begin_signing:', [id]);
        },
        on_sign_progress : function(i) {
            device.execute('tx_on_sign_progress:input:', [id, i]);
        },
        on_finish_signing : function() {
            device.execute('tx_on_finish_signing:', [id]);
        }
    };

    var success = function() {
        device.execute('tx_on_success:', [id]);
        delete pendingTransactions[id];
    };

    var error = function(error) {
        device.execute('tx_on_error:error:', [id, ''+error]);
        delete pendingTransactions[id];
    };

    var value = BigInteger.valueOf(valueString);

    var fee = null;
    var note = null;

    MyWallet.sendFromLegacyAddressToAddress(from, to, value, fee, note, success, error, listener, MyWalletPhone.getSecondPassword(success, error));

    return id;
};

MyWalletPhone.quickSendFromAddressToAccount = function(from, to, valueString) {
    var id = ''+Math.round(Math.random()*100000);

    var listener = {
        on_start : function() {
            device.execute('tx_on_start:', [id]);
        },
        on_begin_signing : function() {
            device.execute('tx_on_begin_signing:', [id]);
        },
        on_sign_progress : function(i) {
            device.execute('tx_on_sign_progress:input:', [id, i]);
        },
        on_finish_signing : function() {
            device.execute('tx_on_finish_signing:', [id]);
        }
    };

    var success = function() {
        device.execute('tx_on_success:', [id]);
        delete pendingTransactions[id];
    };

    var error = function(error) {
        device.execute('tx_on_error:error:', [id, ''+error]);
        delete pendingTransactions[id];
    };

    var value = BigInteger.valueOf(valueString);

    var fee = null;
    var note = null;

    MyWallet.sendFromLegacyAddressToAccount(from, to, value, fee, note, success, error, listener, MyWalletPhone.getSecondPassword(success, error));

    return id;
};

MyWalletPhone.quickSendFromAccountToAddress = function(from, to, valueString) {
    var id = ''+Math.round(Math.random()*100000);

    var listener = {
        on_start : function() {
            device.execute('tx_on_start:', [id]);
        },
        on_begin_signing : function() {
            device.execute('tx_on_begin_signing:', [id]);
        },
        on_sign_progress : function(i) {
            device.execute('tx_on_sign_progress:input:', [id, i]);
        },
        on_finish_signing : function() {
            device.execute('tx_on_finish_signing:', [id]);
        }
    };

    var success = function() {
        device.execute('tx_on_success:', [id]);
        delete pendingTransactions[id];
    };

    var error = function(error) {
        device.execute('tx_on_error:error:', [id, ''+error]);
        delete pendingTransactions[id];
    };

    var value = parseInt(valueString);

    var fee = MyWallet.recommendedTransactionFeeForAccount(from, value);
    var note = null;

    MyWallet.sendBitcoinsForAccount(from, to, value, fee, note, success, error, listener, MyWalletPhone.getSecondPassword(success, error));

    return id;
};

MyWalletPhone.quickSendFromAccountToAccount = function(from, to, valueString) {
    var id = ''+Math.round(Math.random()*100000);

    var listener = {
        on_start : function() {
            device.execute('tx_on_start:', [id]);
        },
        on_begin_signing : function() {
            device.execute('tx_on_begin_signing:', [id]);
        },
        on_sign_progress : function(i) {
            device.execute('tx_on_sign_progress:input:', [id, i]);
        },
        on_finish_signing : function() {
            device.execute('tx_on_finish_signing:', [id]);
        }
    };

    var success = function() {
        device.execute('tx_on_success:', [id]);
        delete pendingTransactions[id];
    };

    var error = function(error) {
        device.execute('tx_on_error:error:', [id, ''+error]);
        delete pendingTransactions[id];
    };

    var value = parseInt(valueString);

    var fee = MyWallet.recommendedTransactionFeeForAccount(from, value);
    var note = null;

    MyWallet.sendToAccount(from, to, value, fee, note, success, error, listener, MyWalletPhone.getSecondPassword(success, error));

    return id;
};

MyWalletPhone.apiGetPINValue = function(key, pin) {
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

            device.execute('on_pin_code_put_response:', [responseObject]);
        },
        error: function (res) {
            if (!res || !res.responseText || res.responseText.length == 0) {
                device.execute('on_error_pin_code_put_error:', ['Unknown Error']);
            } else {
                try {
                    var responseObject = $.parseJSON(res.responseText);

                    responseObject.key = key;
                    responseObject.value = value;

                    device.execute('on_pin_code_put_response:', [responseObject]);
                } catch (e) {
                    device.execute('on_error_pin_code_put_error:', [res.responseText]);
                }
            }
        }
    });
};

MyWalletPhone.newAccount = function(password, email) {
    var success = function(guid, sharedKey, password) {
        device.execute('loading_stop');

        device.execute('on_create_new_account:sharedKey:password:', [guid, sharedKey, password]);
    };

    var error = function(e) {
        device.execute('loading_stop');

        device.execute('on_error_creating_new_account:', [''+e]);
    };

    device.execute('loading_start_new_account');

    MyWallet.createNewWallet(email, password, null, null, success, error);
};

MyWalletPhone.parsePairingCode = function (raw_code) {
    var success = function (pairing_code) {
        device.execute("didParsePairingCode:", [pairing_code]);
    };

    var error = function (e) {
        device.execute("errorParsingPairingCode:", [e]);
    };

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
};

MyWalletPhone.addAddressBookEntry = function(bitcoinAddress, label) {
    MyWallet.addAddressBookEntry(bitcoinAddress, label);

    MyWallet.backupWallet();
};

MyWalletPhone.detectPrivateKeyFormat = function(privateKeyString) {
    try {
        return MyWallet.detectPrivateKeyFormat(privateKeyString);
    } catch(e) {
        return null;
    }
};

MyWalletPhone.hasEncryptedWalletData = function() {
    var data = MyWallet.getEncryptedWalletData();

    return data && data.length > 0;
};

MyWalletPhone.getWsReadyState = function() {
    if (!ws) return -1;

    return ws.readyState;
};

MyWalletPhone.get_history = function() {
    var success = function () {
        console.log('Got wallet history');
        device.execute('loading_stop');
    };
    
    var error = function () {
        console.log('Error getting wallet history');
        device.execute('loading_stop');
    };
    
    device.execute('loading_start_get_history');
    
    MyWallet.get_history(success, error);
};

MyWalletPhone.get_wallet_and_history = function() {
    var success = function () {
        console.log('Got wallet and history');
        device.execute('loading_stop');
    };
    
    var error = function () {
        console.log('Error getting wallet and history');
        device.execute('loading_stop');
    };
    
    device.execute('loading_start_get_wallet_and_history');
    
    MyWallet.getWallet(function() {
        MyWallet.get_history(success, error);
    });
};

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
};

MyWalletPhone.addPrivateKey = function(privateKeyString) {
    var success = function(address) {
        console.log('Add private key success');

        device.execute('on_add_private_key:', [address]);
    };
    var error = function(e) {
        console.log('Add private key Error');

        device.execute('on_error_adding_private_key:', [''+e]);
    };
    var alreadyImportedCallback = function(e) {
        console.log('Add private key Error: already imported');

        device.execute('on_error_adding_private_key:', ['Key already imported']);
    };

    MyWallet.importPrivateKey(privateKeyString, MyWalletPhone.getSecondPassword(success, error), MyWalletPhone.getPrivateKeyPassword, success, alreadyImportedCallback, error);
};

// Shared functions

function simpleWebSocketConnect() {
    if (!MyWallet.getIsInitialized()) {
        // The websocket should only operate when the wallet is initialized. We get calls before and after this is true because we stop and start the websocket for ajax calls
        return;
    }

    console.log('Connecting websocket...');

    if (!window.WebSocket) {
        console.log('No websocket support in JS runtime');
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
    if (!MyWallet.getIsInitialized()) {
        // The websocket should only operate when the wallet is initialized. We get calls before and after this is true because we stop and start the websocket for ajax calls
        return;
    }

    console.log('Disconnecting websocket...');

    if (!window.WebSocket) {
        console.log('No websocket support in JS runtime');
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


// Get passwords

MyWalletPhone.getPrivateKeyPassword = function(callback) {
    // Due to the way the JSBridge handles calls with success/error callbacks, we need a first argument that can be ignored
    device.execute("getPrivateKeyPassword:", ["discard"], function(pw) {
                   callback(pw,
                            function () {
                                console.log('BIP38 private key import: correct password');
                            },
                            function () {
                                console.log('BIP38 private key import: password incorrect');
                                device.execute('makeNotice:id:message:', ['error', '', 'Incorrect Passphrase']);
                            });
                   }, function(msg) { console.log('Error' + msg); });
};

MyWalletPhone.getSecondPassword = function(success, error) {
    var fun = function(callback) {
        // Due to the way the JSBridge handles calls with success/error callbacks, we need a first argument that can be ignored
        device.execute("getSecondPassword:", ["discard"], function(pw) {
                       callback(pw,
                                function () {
                                    console.log('Second password correct');
                                },
                                function () {
                                    console.log('Second password incorrect');
                                });
                       }, function(msg) {
                           console.log('Error: ' + msg);
                           error && error('');
                       });
    };
    
    return fun;
};


// Overrides

MyWallet.getWebWorkerLoadPrefix = function() {
    return '';
};

ImportExport.Crypto_scrypt = function(passwd, salt, N, r, p, dkLen, callback) {
    if(typeof(passwd) !== 'string') {
        passwd = passwd.toJSON().data;
    }

    if(typeof(salt) !== 'string') {
        salt = salt.toJSON().data;
    }

    device.execute('crypto_scrypt:salt:n:r:p:dkLen:', [passwd, salt, N, r, p, dkLen], function(buffer) {
        var bytes = new Buffer(buffer, 'hex');

        callback(bytes);
    }, function(e) {
        error(''+e);
    });
};

MyStore.get_old = MyStore.get;
MyStore.get = function(key, callback) {
    // Disallow fetching of the guid
    if (key == 'guid') {
        callback();
        return;
    }

    MyStore.get_old(key, callback);
};

// TODO what should this value be?
MyWallet.getNTransactionsPerPage = function() {
    return 50;
};
