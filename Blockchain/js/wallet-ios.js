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

min = false;
isExtension = true;
APP_NAME = 'javascript_iphone_app';
APP_VERSION = '0.1 BETA';
root = "https://blockchain.info/";
resource = '';

// Hack to prevent JS Error
function showLabelAddressModal() {}

$(document).ready(function() {
    MyWallet.logout = function() {}
});

MyWallet.getWebWorkerLoadPrefix = function() {
    return '';
}

MyWallet.addEventListener(function (event, obj) {
    if (obj) {
        event += ':';
    }

    device.execute(event, [obj]);
});

MyWalletPhone.generateNewKey = function() {
    $("#new-addr").click();
}

MyWalletPhone.cancelTxSigning = function() {
    for (var key in pendingTransactions) {
        pendingTransactions[key].cancel();
    }
}

function setScryptImportExport() {
    ImportExport.Crypto_scrypt = function(passwd, salt, N, r, p, dkLen, callback) {
        device.execute('crypto_scrypt:salt:n:r:p:dkLen:', [passwd, salt, N, r, p, dkLen], function(buffer) {
            var bytes = Crypto.util.hexToBytes(buffer);
            callback(bytes);
        }, function(e) {
            error(''+e);
        });
    }
}

MyWalletPhone.quickSend = function(from, to, valueString) {
    var id = ''+Math.round(Math.random()*100000);

    (function(id) {
        var listener = {
            on_success : function(e) {
                device.execute('tx_on_success:', [id]);
                delete pendingTransactions[id];
            },
            on_start : function() {
                device.execute('tx_on_start:', [id]);
            },
            on_error : function(e) {
                device.execute('tx_on_error:error:', [id, ''+e]);
                delete pendingTransactions[id];
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

        MyWallet.getSecondPassword(function() {
            loadScript('signer', function() {
                try {
                    if (Object.keys(pendingTransactions).length > 0) {
                        throw 'Transaction already pending';
                    }

                    var obj = initNewTx();

                    obj.ask_for_private_key = function(success, error, address) {
                        device.execute('ask_for_private_key:', [address], function(privateKeyString) {
                            try {
                                var format = MyWallet.detectPrivateKeyFormat(privateKeyString);

                                if (format == 'bip38') {
                                    loadScript('import-export', function() {
                                        setScryptImportExport();

                                        MyWallet.getPassword($('#import-private-key-password'), function(_password) {
                                            ImportExport.parseBIP38toECKey(privateKeyString, _password, function(key, isCompPoint) {
                                                success(key);
                                            }, error);
                                        }, error);
                                    }, error);
                                } else {
                                    var key = MyWallet.privateKeyStringToKey(privateKeyString, format);

                                    if (key == null) {
                                        throw 'Could not decode private key';
                                    }

                                    success(key);
                                }
                            } catch(e) {
                                error(e);
                            }
                        }, error);
                    }

                    pendingTransactions[id] = obj;

                    if (from && from.length > 0) {
                        obj.from_addresses = [from];
                    } else {
                        obj.from_addresses = MyWallet.getActiveAddresses();
                    }

                    var value = BigInteger.valueOf(valueString);

                    if (!value || value.compareTo(BigInteger.ZERO) == 0) {
                        throw 'Invalid Send Value';
                    }

                    obj.to_addresses.push({address: new Bitcoin.Address(to), value: value});

                    obj.addListener(listener);
                       
                    obj.start();
                } catch (e){
                    listener.on_error(e);
                }
            }, function(e) {
                listener.on_error(e);
            });
        }, function(e) {
            listener.on_error(e);
        });
    })(id);

    return id;
}

MyWalletPhone.apiGetPINValue = function(key, pin) {
    MyWallet.setLoadingText('Retrieving PIN Code');

    $.ajax({
        type: "POST",
        url: root + 'pin-store',
        timeout: 30000,
        dataType: 'json',
        data: {
           format: 'json',
           method: 'get',
           pin : pin,
           key : key
       },
       success: function (responseObject) {
           device.execute('on_pin_code_get_response:', [responseObject])
       },
       error: function (res) {
           if (!res || !res.responseText || res.responseText.length == 0) {
                device.execute('on_error_pin_code_get_error:', ['Unknown Error']);
           } else {
                try {
                    var responseObject = $.parseJSON(res.responseText);
           
                    if (!responseObject) {
                        throw 'Response Object nil';
                    }
           
                    device.execute('on_pin_code_get_response:', [responseObject])
                } catch (e) {
                    device.execute('on_error_pin_code_get_error:', [res.responseText]);
                }
           }
       }
    });
}

MyWalletPhone.pinServerPutKeyOnPinServerServer = function(key, value, pin) {
    MyWallet.setLoadingText('Saving PIN Code');
    
    $.ajax({
        type: "POST",
        url: root + 'pin-store',
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

MyWalletPhone.hasEncryptedWalletData = function() {
    var data = MyWallet.getEncryptedWalletData();
    
    return data && data.length > 0;
}

MyWalletPhone.getWsReadyState = function() {
    if (!ws) return -1;

    return ws.readyState;
}

MyWalletPhone.isValidAddress = function(addrstring) {
    try {
        new Bitcoin.Address(addrstring).toString();

        return true;
    } catch (e) {
        return false;
    }
}

MyWalletPhone.get_wallet_and_history = function() {
    $('#refresh').click();
}

MyWalletPhone.setPassword = function(password) {
    $('#restore-password').val(password);

    $('#restore-wallet-continue').click();
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

MyWalletPhone.newAccount = function(password, email) {
    loadScript('wallet-signup', function() {
        MyWalletSignup.generateNewWallet(password, email, function(guid, sharedKey, password) {
            MyStore.clear();
            device.execute('on_create_new_account:sharedKey:password:', [guid, sharedKey, password]);
        }, function (e) {
            device.execute('on_error_creating_new_account:', [''+e]);
        });
    });
}

MyWalletPhone.getMultiAddrResponse = function() {
    var obj = {};

    obj.transactions = MyWallet.getTransactions();
    obj.total_received = MyWallet.getTotalReceived();
    obj.total_sent = MyWallet.getTotalSent();
    obj.final_balance = MyWallet.getFinalBalance();
    obj.n_transactions = MyWallet.getNTransactions();
    obj.addresses = MyWallet.getAllAddresses();

    obj.symbol_local = symbol_local;
    obj.symbol_btc = symbol_btc;

    return obj;
}

MyWalletPhone.addPrivateKey = function(privateKeyString) {
    (function(privateKeyString) {
        function error(e) {
            device.execute('on_error_adding_private_key:', [''+e]);
        }

        function reallyInsertKey(key, compressed) {
            try {
                if (MyWallet.addPrivateKey(key, {compressed : compressed, app_name : APP_NAME, app_version : APP_VERSION})) {

                    var addr = compressed ? key.getBitcoinAddressCompressed().toString() : key.getBitcoinAddress().toString();

                    device.execute('on_add_private_key:', [addr]);
     
                    MyWallet.backupWallet('update', function() {
                        MyWallet.get_history();
                    });
                } else {
                    throw 'Unable to add private key for bitcoin address ' + addr;
                }
            } catch (e) {
                error(e);
            }
        }

        MyWallet.getSecondPassword(function() {
            try {
                var format = MyWallet.detectPrivateKeyFormat(privateKeyString);

                if (format == 'bip38') {
                    loadScript('import-export', function() {
                        setScryptImportExport();

                        MyWallet.getPassword($('#import-private-key-password'), function(_password) {
                            ImportExport.parseBIP38toECKey(privateKeyString, _password, function(key, isCompPoint) {
                                //success
                                reallyInsertKey(key, isCompPoint);
                            }, error);
                        }, error);
                    }, error);
                } else {
                    var key = MyWallet.privateKeyStringToKey(privateKeyString, format);

                    reallyInsertKey(key, format == 'compsipa');
                }
            } catch (e) {
                error(e);
            }
        }, error);
    })(privateKeyString);
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

MyWallet.setLoadingText = function(txt) {
    device.execute('setLoadingText:', [txt]);
}

MyWallet.getPassword = function(modal, success, error) {
    device.execute("getPassword:", [modal.selector], success, error);
}

MyWallet.makeNotice = function(type, _id, msg) {
    device.execute('makeNotice:id:message:', [''+type, ''+_id, ''+msg]);
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

MyWallet.showNotification = function() { }

MyWalletPhone.decrypt = function(data, password, pbkdf2_iterations) {
    return Crypto.AES.decrypt(data, password, { mode: new Crypto.mode.CBC(Crypto.pad.iso10126), iterations : pbkdf2_iterations});
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

        MyWallet.setLoadingText('Decrypting Pairing Code');

        $.ajax({
            type: "POST",
            url: root + 'wallet',
            timeout: 60000,
            data: {
                format: 'plain',
                method: 'pairing-encryption-password',
                guid: guid
            },
            success: function (encryption_phrase) {
                try {
               
                    var decrypted = MyWallet.decrypt(encrypted_data, encryption_phrase, MyWallet.getDefaultPbkdf2Iterations(), function (decrypted) {
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
                            password: UTF8.bytesToString(Crypto.util.hexToBytes(components2[1]))
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

BlockchainAPI.get_history = function(success, error, tx_filter, offset, n) {
    MyWallet.setLoadingText('Loading transactions');

    var clientTime=(new Date()).getTime();

    if (!tx_filter) tx_filter = 0;
    if (!offset) offset = 0;
    if (!n) n = 0;

    var data = {
        active : MyWallet.getActiveAddresses().join('|'),
        format : 'json',
        filter : tx_filter,
        offset : offset,
        no_compact : true,
        ct : clientTime,
        n : n,
        no_buttons : true,
        language : MyWallet.getLanguage(),
        guid : MyWallet.getGuid()
    };

    $.retryAjax({
        type: "POST",
        dataType: 'json',
        url: root +'multiaddr',
        data: data,
        timeout: 60000,
        retryLimit: 2,
        success: function(obj) {
            if (obj.error != null) {
                MyWallet.makeNotice('error', 'misc-error', obj.error);
            }

            MyWallet.handleNTPResponse(obj, clientTime);

            try {
                //Cache results to show next login
                if (offset == 0 && tx_filter == 0) {
                    MyStore.put('multiaddr', JSON.stringify(obj));
                }

                success(obj);
            } catch (e) {
                MyWallet.makeNotice('error', 'misc-error', e);

                error();
            }
        },
        error : function(data) {
            if (data.responseText)
                MyWallet.makeNotice('error', 'misc-error', data.responseText);
            else
                MyWallet.makeNotice('error', 'misc-error', 'Error Downloading Wallet Balance');

            error();
        }
    });
}
