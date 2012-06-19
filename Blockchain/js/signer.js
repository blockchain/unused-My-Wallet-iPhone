function exceptionToString(err) {
    var vDebug = "";
    for (var prop in err)  {
        vDebug += "property: "+ prop+ " value: ["+ err[prop]+ "]\n";
    }
    return "toString(): " + " value: [" + err.toString() + "]";
}

try {
//Init WebWoker
//Window is not defined in WebWorker
    if (typeof window == "undefined" || !window) {
        var window = {};

        importScripts('bitcoinjs.min.js');

        self.addEventListener('message', function(e) {
            var data = e.data;
            switch (data.cmd) {
                case 'sign_input':
                    try {
                        var tx = new Bitcoin.Transaction(data.tx);

                        var connected_script = new Bitcoin.Script(data.connected_script);

                        var signed_script = signInput(tx, data.outputN, data.priv_to_use, connected_script);
                        if (signed_script) {
                            self.postMessage({cmd : 'on_sign', script : signed_script, outputN : data.outputN});
                        } else {
                            throw 'Unknown Error Signing Script ' + data.outputN;
                        }

                    } catch (e) {
                        self.postMessage({cmd : 'on_error', e : exceptionToString(e)});
                    }
                    break;
                default:
                    self.postMessage({cmd : 'on_error', e : 'Unknown Command'});
            };
        }, false);
    }
} catch (e) { }

Bitcoin.Transaction.prototype.addOutputScript = function (script, value) {
    if (arguments[0] instanceof Bitcoin.TransactionOut) {
        this.outs.push(arguments[0]);
    } else {
        if (value instanceof BigInteger) {
            value = value.toByteArrayUnsigned().reverse();
            while (value.length < 8) value.push(0);
        } else if (Bitcoin.Util.isArray(value)) {
            // Nothing to do
        }

        this.outs.push(new Bitcoin.TransactionOut({
            value: value,
            script: script
        }));
    }
};

function getUnspentOutputs(fromAddresses, success, error) {
    //Get unspent outputs
    setLoadingText('Getting Unspent Outputs');

    $.ajax({
        type: "POST",
        url: root +'unspent',
        data: {'addr[]' : fromAddresses, 'format' : 'json'},
        converters: {"* text": window.String, "text html": true, "text json": window.String, "text xml": $.parseXML},
        success: function(data) {
            try {
                var obj = $.parseJSON(data);

                if (obj == null) {
                    throw 'Unspent returned null object';
                }

                if (obj.error != null) {
                    throw obj.error;
                }

                if (obj.notice != null) {
                    makeNotice('notice', 'misc-notice', obj.notice);
                }
           
                success(obj);
            } catch (e) {
                error(e);
            }
        },
        error: function (data) {
            try {
                if (data.responseText)
                    throw data.responseText;
                else
                    throw 'Error Contacting Server. No unspent outputs available in cache.';

            } catch (e) {
                error(e);
            }
        }
    });
}

function signInput(tx, inputN, base58Key, connected_script) {

    var pubKeyHash = connected_script.simpleOutPubKeyHash();

    var inputBitcoinAddress = new Bitcoin.Address(pubKeyHash).toString();

    var key = new Bitcoin.ECKey(base58Key);

    var compressed;
    if (key.getBitcoinAddress().toString() == inputBitcoinAddress.toString()) {
        compressed = false;
    } else if (key.getBitcoinAddressCompressed().toString() == inputBitcoinAddress.toString()) {
        compressed = true;
    } else {
        throw 'Private key does not match bitcoin address ' + inputBitcoinAddress.toString() + ' = ' + key.getBitcoinAddress().toString() + ' | '+ key.getBitcoinAddressCompressed().toString();
    }

    var hashType = parseInt(1); // SIGHASH_ALL

    var hash = tx.hashTransactionForSignature(connected_script, inputN, hashType);

    var rs = key.sign(hash);

    var signature = Bitcoin.ECDSA.serializeSig(rs.r, rs.s);

    // Append hash type
    signature.push(hashType);

    var script;

    if (compressed)
        script = Bitcoin.Script.createInputScript(signature, key.getPubCompressed());
    else
        script = Bitcoin.Script.createInputScript(signature, key.getPub());

    if (script == null) {
        throw 'Error creating input script';
    }

    return script;
}

function formatAddresses(m, faddresses, resolve_labels) {
    var str = '';
    if (faddresses.length == 1) {
        var addr_string = faddresses[0].toString();

        if (resolve_labels && addresses[addr_string] != null && addresses[addr_string].label != null)
            str = addresses[addr_string].label;
        else if (resolve_labels && address_book[addr_string] != null)
            str = address_book[addr_string];
        else
            str = addr_string;

    } else {
        str = 'Escrow (<i>';
        for (var i = 0; i < faddresses.length; ++i) {
            str += faddresses[i].toString() + ', ';
        }

        str = str.substring(0, str.length-2);

        str += '</i> - ' + m + ' Required)';
    }
    return str;
}

function apiResolveFirstbits(addr, success, error) {
    
    setLoadingText('Getting Firstbits');
    
    $.get(root + 'q/resolvefirstbits/'+addr).success(
    function(data) {     
        if (data == null || data.length == 0)
          error();
        else
          success(data);
    }).error(function(data) {
      error();
    });
}

/*

 pending_transaction {
 change_address : BitcoinAddress
 from_addresses : [String]
 to_addresses : [{address: BitcoinAddress, value : BigInteger}]
 generated_addresses : [String]
 extra_private_keys : {addr : String, priv : ECKey}
 fee : BigInteger
 on_error : function
 on_success : function
 on_ready_to_send : function
 }
 */
function initNewTx() {
    var pending_transaction = {
        generated_addresses : [],
        to_addresses : [],
        fee : BigInteger.ZERO,
        extra_private_keys : [],
        listeners : [],
        is_cancelled : false,
        addListener : function(listener) {
            this.listeners.push(listener);
        },
        invoke : function (cb, obj, ob2) {
            for (var key in this.listeners) {
                if (this.listeners[key][cb])
                    this.listeners[key][cb].call(this, obj, ob2);
            }
        }, start : function() {
            var self = this;

            try {

                self.invoke('on_start');

                getUnspentOutputs(self.from_addresses, function (obj) {
                    try {
                        if (obj.unspent_outputs == null || obj.unspent_outputs.length == 0) {
                            throw 'No Free Outputs To Spend';
                        }

                        self.unspent = [];

                        for (var i = 0; i < obj.unspent_outputs.length; ++i) {
                            var script;
                            try {
                                script = new Bitcoin.Script(Crypto.util.hexToBytes(obj.unspent_outputs[i].script));
                            } catch(e) {
                                makeNotice('error', 'misc-error', 'Error decoding script: ' + e); //Not a fatal error
                                continue;
                            }
                            var out = {script : script,
                                value : BigInteger.fromByteArrayUnsigned(Crypto.util.hexToBytes(obj.unspent_outputs[i].value_hex)),
                                tx_output_n : obj.unspent_outputs[i].tx_output_n,
                                tx_hash : obj.unspent_outputs[i].tx_hash,
                                confirmations : obj.unspent_outputs[i].confirmations
                            };

                            self.unspent.push(out);
                        }

                        self.makeTransaction();
                    } catch (e) {
                        self.error(e);
                    }
                }, function(e) {
                    self.error(e);
                });
            } catch (e) {
                self.error(e);
            }
        },
        //Select Outputs and Construct transaction
        makeTransaction : function() {            
            var self = this;

            try {
                this.selected_outputs = [];

                var txValue = BigInteger.ZERO;

                for (var i = 0; i < this.to_addresses.length; ++i) {
                    txValue = txValue.add(this.to_addresses[i].value);
                }

                var isSweep = (this.to_addresses.length == 0);

                var isEscrow = false;

                //If we have any escrow outputs we increase the fee to 0.05 BTC
                for (var i =0; i < this.to_addresses.length; ++i) {
                    var addrObj = this.to_addresses[i];
                    if (addrObj.m != null) {
                        isEscrow = true;
                        break;
                    }
                }

                var availableValue = BigInteger.ZERO;

                //Add the miners fees
                if (this.fee != null)
                    txValue = txValue.add(this.fee);

                var priority = 0;

                for (var i in this.unspent) {
                    var out = this.unspent[i];

                    try {
                        var addr = new Bitcoin.Address(out.script.simpleOutPubKeyHash()).toString();

                        if (addr == null) {
                            throw 'Unable to decode output address from transaction hash ' + out.tx_hash;
                        }

                        if (this.from_addresses != null && this.from_addresses.length > 0 && $.inArray(addr.toString(), this.from_addresses) == -1) {
                            continue;
                        }

                        var hexhash = Crypto.util.hexToBytes(out.tx_hash);

                        var b64hash = Crypto.util.bytesToBase64(Crypto.util.hexToBytes(out.tx_hash));

                        var new_in =  new Bitcoin.TransactionIn({outpoint: {hash: b64hash, hexhash: hexhash, index: out.tx_output_n, value:out.value}, script: out.script, sequence: 4294967295});

                        //If the output happens to be greater than tx value then we can make this transaction with one input only
                        //So discard the previous selected outs
                        if (out.value.compareTo(txValue) >= 0) {
                            this.selected_outputs = [new_in];

                            priority = out.value * out.confirmations;

                            availableValue = out.value;

                            break;
                        } else {
                            //Otherwise we add the value of the selected output and continue looping if we don't have sufficient funds yet
                            this.selected_outputs.push(new_in);

                            priority += out.value * out.confirmations;

                            availableValue = availableValue.add(out.value);

                            if (!isSweep && availableValue.compareTo(txValue) >= 0)
                                break;
                        }

                    } catch (e) {
                        //An error, but probably recoverable
                        makeNotice('info', 'tx-error', e);
                    }
                }

                if (availableValue.compareTo(txValue) < 0) {
                    this.error('Insufficient funds. Value Needed ' +  formatBTC(txValue.toString()) + ' BTC. Available amount ' + formatBTC(availableValue.toString()) + ' BTC');
                    return;
                }

                if (this.selected_outputs.length == 0) {
                    this.error('No Available Outputs To Spend.');
                    return;
                }

                var sendTx = new Bitcoin.Transaction();

                for (var i = 0; i < this.selected_outputs.length; i++) {
                    sendTx.addInput(this.selected_outputs[i]);
                }

                var askforfee = false;
                for (var i =0; i < this.to_addresses.length; ++i) {
                    var addrObj = this.to_addresses[i];
                    if (addrObj.m != null) {
                        sendTx.addOutputScript(Bitcoin.Script.createMultiSigOutputScript(addrObj.m, addrObj.pubkeys), addrObj.value);
                    } else {
                        sendTx.addOutput(addrObj.address, addrObj.value);
                    }
                }

                //Now deal with the change
                var	changeValue = availableValue.subtract(txValue);
                if (changeValue.compareTo(BigInteger.ZERO) > 0) {
                    if (this.change_address != null) //If chenge address speicified return to that
                        sendTx.addOutput(this.change_address, changeValue);
                    else if (!isSweep && this.from_addresses != null && this.from_addresses.length > 0) //Else return to the from address if specified
                        sendTx.addOutput(new Bitcoin.Address(this.from_addresses[0]), changeValue);
                    else { //Otherwise return to random unarchived
                        sendTx.addOutput(new Bitcoin.Address(getPreferredAddress()), changeValue);
                    }
                }

                var forceFee = false;

                //Check for tiny outputs
                for (var i = 0; i < sendTx.outs.length; ++i) {
                    var out = sendTx.outs[i];

                    var array = out.value.slice();
                    array.reverse();
                    var val =  new BigInteger(array);

                    //If less than 0.0005 BTC force fee
                    if (val.compareTo(BigInteger.valueOf(50000)) < 0) {
                        forceFee = true;
                    } else if (val.compareTo(BigInteger.valueOf(1000000)) < 0) { //If less than 0.01 BTC show warning
                        askforfee = true;
                    }
                }

                //Estimate scripot sig (Cannot use serialized tx size yet becuase we haven't signed the inputs)
                //18 bytes standard header
                //standard scriptPubKey 24 bytes
                //Stanard scriptSig 64 bytes
                var estimatedSize = sendTx.serialize(sendTx).length + (114 * sendTx.ins.length);

                priority /= estimatedSize;

                var kilobytes = parseInt(estimatedSize / 1024);

                var fee_is_zero = !self.fee || self.fee.compareTo(BigInteger.ZERO) == 0;

                //Priority under 57 million requires a 0.0005 BTC transaction fee (see https://en.bitcoin.it/wiki/Transaction_fees)
                if (fee_is_zero && forceFee) {
                    //Forced Fee
                    self.fee = BigInteger.valueOf(50000);

                    self.makeTransaction();
                } else if (fee_is_zero && (priority < 57600000 || kilobytes > 1 || isEscrow || askforfee)) {
                    self.ask_for_fee(function() {

                        var bi_kilobytes = BigInteger.valueOf(kilobytes);
                        if (bi_kilobytes && bi_kilobytes.compareTo(BigInteger.ZERO) > 0)
                            self.fee = BigInteger.valueOf(100000).multiply(bi_kilobytes); //0.001 BTC * kilobytes
                        else
                            self.fee = BigInteger.valueOf(50000); //0.0005 BTC

                        self.makeTransaction();
                    }, function() {
                        self.tx = sendTx;

                        self.determinePrivateKeys(function() {
                            self.signInputs();
                        });
                    });
                } else {
                    self.tx = sendTx;

                    self.determinePrivateKeys(function() {
                        self.signInputs();
                    });
                }
            } catch (e) {
                this.error(e);
            }
        },
        ask_for_fee : function(yes, no) {
            yes();
        },
        determinePrivateKeys: function(success) {
            var self = this;

            try {
                var tmp_cache = {};

                for (var i in self.selected_outputs) {
                    var connected_script = self.selected_outputs[i].script;

                    if (connected_script.priv_to_use == null) {
                        var pubKeyHash = connected_script.simpleOutPubKeyHash();
                        var inputAddress = new Bitcoin.Address(pubKeyHash).toString();

                        //Find the matching private key
                        if (tmp_cache[inputAddress]) {
                            connected_script.priv_to_use = tmp_cache[inputAddress];
                        } else if (self.extra_private_keys[inputAddress]) {
                            connected_script.priv_to_use = Bitcoin.Base58.decode(self.extra_private_keys[inputAddress]);
                        } else if (addresses[inputAddress] && addresses[inputAddress].priv) {
                            connected_script.priv_to_use = decodePK(addresses[inputAddress].priv);
                        }

                        if (connected_script.priv_to_use == null) {
                            self.ask_for_private_key(function (key) {
                                try {
                                    if (inputAddress == key.getBitcoinAddress().toString() || inputAddress == key.getBitcoinAddressCompressed().toString()) {
                                        self.extra_private_keys[inputAddress] = Bitcoin.Base58.encode(key.priv);

                                        self.determinePrivateKeys(success); //Try Again
                                    } else {
                                        throw 'The private key you entered does not match the bitcoin address';
                                    }
                                } catch (e) {
                                    self.error(e);
                                }
                            }, function(e) {
                                self.error(e);
                            }, inputAddress);

                            return false;
                        } else {
                            //Performance optimization
                            //Only Decode the key once sand save it in a temporary cache
                            tmp_cache[inputAddress] = connected_script.priv_to_use;
                        }
                    }
                }

                success();
            } catch (e) {
                self.error(e);
            }
        },
        signWebWorker : function(success, error) {
            try {
                var self = this;
                var nSigned = 0;
                var nWorkers = Math.min(2, self.tx.ins.length);

                this.worker = [];
                for (var i = 0; i < nWorkers; ++i)  {
                    this.worker[i] =  new Worker('signer.js');

                    this.worker[i].addEventListener('message', function(e) {
                       try {
                            var data = e.data;

                            switch (data.cmd) {
                                case 'on_sign':
                                    self.invoke('on_sign_progress', parseInt(data.outputN)+1);

                                    self.tx.ins[data.outputN].script  = new Bitcoin.Script(data.script);

                                    ++nSigned;

                                    if (nSigned == self.tx.ins.length) {
                                        self.terminateWorkers();
                                        success();
                                    }

                                    break;
                                case 'on_error': {
                                    throw data.e;
                                }
                            };
                        } catch (e) {
                            self.terminateWorkers();
                            error(e);
                        }
                    }, false);
                    
                    this.worker[i].addEventListener('error', function(e) {
                        error(e); 
                    });  
                }

                for (var outputN in self.selected_outputs) {
                    var connected_script = self.selected_outputs[outputN].script;
                    this.worker[outputN % nWorkers].postMessage({cmd : 'sign_input', tx : self.tx, outputN : outputN, priv_to_use : connected_script.priv_to_use, connected_script : connected_script});
                }
            } catch (e) {
                error(e);
            }
        },
        signNormal : function(success, error) {
            var self = this;
            var outputN = 0;

            signOne = function() {
                setTimeout(function() {
                    if (self.is_cancelled)
                        return;
                           
                    try {
                        self.invoke('on_sign_progress', outputN+1);

                        var connected_script = self.selected_outputs[outputN].script;

                        var signed_script = signInput(self.tx, outputN, connected_script.priv_to_use, connected_script);

                        if (signed_script) {
                            self.tx.ins[outputN].script = signed_script;

                            ++outputN;

                            if (outputN == self.tx.ins.length) {
                                success();
                            } else {
                                signOne(); //Sign The Next One
                            }
                        } else {
                            throw 'Unknown error signing transaction';
                        }
                    } catch (e) {
                        error(e);
                    }

                }, 100);
            };

            signOne();
        },
        signInputs : function() {            
            var self = this;

            try {
                self.invoke('on_begin_signing');

                var success = function() {
                    self.invoke('on_finish_signing');

                    self.is_ready = true;
                    self.ask_to_send();
                };

                self.signWebWorker(success, function(e) {
                    self.signNormal(success, function(e){
                        self.error(e);
                    });
                });
            } catch (e) {
                self.error(e);
            }
        },
        terminateWorkers : function() {            
            if (this.worker) {
                for (var i in this.worker)  {
                    this.worker[i].terminate();
                }
            }
        },
        cancel : function() {               
            if (!this.has_pushed) {
                this.terminateWorkers();
                this.is_cancelled = true;
                this.error('Transaction Cancelled');
            }
        },
        send : function() {
            var self = this;
            
            if (self.is_cancelled) {
                self.error('This transaction has already been cancelled');
                return;
            }
            
            if (!self.is_ready) {
                self.error('Transaction is not ready to send yet');
                return;
            }

            if (self.generated_addresses.length > 0) {
                self.has_saved_addresses = true;

                backupWallet('update', function() {
                    self.pushTx();
                }, function() {
                    self.error('Error Backing Up Wallet. Cannot Save Newly Generated Keys.')
                });
            } else {
                self.pushTx();
            }
        },
        pushTx : function() {
            
            var self = this;

            if (self.is_cancelled)
                return;
                
            try {
                var s = this.tx.serialize();

                var hex = Crypto.util.bytesToHex(s);

                if (hex.length >= 32768) {
                    this.error('My wallet cannot handle transactions over 32KB in size. Please try splitting your transaction,');
                }

                setLoadingText('Sending Transaction');

                self.has_pushed = true;

                $.post(root + "pushtx", { format : "plain", tx: hex }, function(data) {
                    try {
                        self.success();
                    } catch (e) {
                        self.error(e);
                    }
                }).error(function(data) {
                    self.error(data.responseText);
                });

            } catch (e) {
                self.error(e);
            }
        },
        ask_for_private_key : function(success, error) {
            error('Cannot ask for private key without user interaction disabled');
        },
        //Debug Print
        ask_to_send : function() {
            var self = this;

            for (var i = 0; i < self.tx.ins.length; ++i) {
                var input = self.tx.ins[i];

                console.log('From : ' + new Bitcoin.Address(input.script.simpleInPubKeyHash()) + ' => ' + input.outpoint.value.toString());
            }

            var isFirst = true;
            for (var i = 0; i < self.tx.outs.length; ++i) {
                var out = self.tx.outs[i];
                var out_addresses = [];

                var m = out.script.extractAddresses(out_addresses);

                var array = out.value.slice();

                array.reverse();

                var val =  new BigInteger(array);

                console.log('To: ' + formatAddresses(m, out_addresses) + ' => ' + val.toString());
            }

            self.send();
        },
        error : function(error) {
            if (this.is_cancelled) //Only call once
                return;

            this.is_cancelled = true;

            if (!this.has_pushed && this.generated_addresses.length > 0) {
                //When an error occurs during send (or user cancelled) we need to remove the addresses we generated
                for (var key in this.generated_addresses) {
                    internalDeleteAddress(this.generated_addresses[key]);
                }

                if (this.has_saved_addresses)
                    backupWallet();
            }

            this.invoke('on_error', error);
        },
        success : function() {
            this.invoke('on_success');
        }
    };

    var base_listener = {
        on_error : function(e) {
            console.log(e);
            
            if(e)
                makeNotice('error', 'tx-error', e);

            $('.send').attr('disabled', false);
        },
        on_success : function(e) {
            try {
                $('.send').attr('disabled', false);
            } catch (e) {
                console.log(e);
            }
        },
        on_start : function(e) {
            $('.send').attr('disabled', true);
        },
        on_begin_signing : function() {
            this.start = new Date().getTime();
        },
        on_finish_signing : function() {
            console.log('Took ' + (new Date().getTime() - this.start) + 'ms');
        }
    };

    pending_transaction.addListener(base_listener);

    return pending_transaction;
}
