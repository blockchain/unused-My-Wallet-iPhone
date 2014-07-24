
/*
 Copyright (c) 2010, Dante Torres All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.

 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.

 * Neither the name of the author nor the names of its
 contributors may be used to endorse or promote products derived from
 this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */

/*
 This javascript code is part of the JSBridge api. It is used to communicate
 data to Objective-C code through a UIWebView.
 */

// Counts the number of objects communicated to the Objective-C code.
// It is used to index data in the JSBridge_objArray.
var JSBridge_objCount = 0;

var JSBridge_pendingObjIDs = {};

// Keeps the objects that should be communicated to the Objective-C code.
var JSBridge_objArray = new Array();

var JSBridge_objResponses = new Array();

/*
 Receives as input an image object and returns its data
 encoded in a base64 string.

 This piece of code was based on Matthew Crumley's post
 at http://stackoverflow.com/questions/934012/get-image-data-in-javascript.
 */
function getBase64Image(img) {
    // Create an empty canvas element
    var canvas = document.createElement("canvas");

    var newImg = new Image();
    newImg.src = img.src;
    canvas.width = newImg.width;
    canvas.height = newImg.height;

    // Copy the image contents to the canvas
    var ctx = canvas.getContext("2d");
    ctx.drawImage(newImg, 0, 0);

    // Get the data-URL formatted image
    var dataURL = canvas.toDataURL("image/png");

    return dataURL.replace(/^data:image\/(png|jpg);base64,/, "");
}

/*
 Builds an empty instance of a JSBridge object.
 */
function JSBridgeObj()
{
    this.objectJson = {};
    this.addObject = JSBridgeObj_AddObject;
    this.sendBridgeObject = JSBridgeObj_SendObject;
}

/*
 The addObject method implementation for the JSBridge object.
 */
function JSBridgeObj_AddObject(id, obj)
{
    var json_obj = {};
    
    json_obj[id] = {
        value : obj,
        type : typeof(obj)
    }
        
    $.extend(this.objectJson, json_obj);
}


var device = {
    execute: function(func_name, args, success, error) {
        var obj = new JSBridgeObj();
    
        obj.addObject("function", func_name);
        
        if (success) {
            obj.addObject("success", "TRUE");
        }
        
        if (error) {
            obj.addObject("error", "TRUE");
        }
        
        if (args) {
            if (args.length >= 1) {
                obj.addObject("arg1", args[0]);
            }
            
            if (args.length >= 2) {
                obj.addObject("arg2", args[1]);
            }
        
            if (args.length >= 3) {
                obj.addObject("arg3", args[2]);
            }
            
            if (args.length >= 4) {
                obj.addObject("arg4", args[3]);
            }
        }
        
        obj.sendBridgeObject(success, error);
    }
}

/*
 This method sends the object to the Objective-C code. Basically,
 it tries to load a special URL, which passes the object id.
 */
function JSBridgeObj_SendObject(success, error)
{
    JSBridge_objArray[JSBridge_objCount] = this.objectJson;

    JSBridge_pendingObjIDs[JSBridge_objCount] = {
        JSBridge_objCount : JSBridge_objCount,
        success : success,
        error : error
    };

    window.location.href = "JSBridge://ReadNotificationWithId=" + Object.keys(JSBridge_pendingObjIDs).join(',');

    JSBridge_objCount++;
}


/*
 This method is invoked by the Objective-C code. It retrieves the json string representation
 of a JSBridge object given its id.
 */
function JSBridge_getJsonStringForObjectWithId(objId)
{
    var jsonStr = JSBridge_objArray[objId];

    JSBridge_objArray[objId] = null;
    
    return JSON.stringify(jsonStr);
}

function JSBridge_setResponseWithId(objId, value, success)
{
    JSBridge_objResponses[objId] = {obj: value, success: success};

    var responseObj = JSBridge_pendingObjIDs[objId];
    
    if (responseObj && (responseObj.success || responseObj.error)) {
        var responseContainer = JSBridge_objResponses[responseObj.JSBridge_objCount];
        
        if (responseContainer) {
            if (responseContainer && responseContainer.success) {
                if (responseObj.success)
                    responseObj.success(responseContainer ? responseContainer.obj : null);
            } else {
                if (responseObj.error)
                    responseObj.error(responseContainer ? responseContainer.obj : null);
            }
        }
    }
    
    //Received response, remove from pending
    delete JSBridge_pendingObjIDs[objId];
}

/*
 Checks if an object is an array.

 This piece of code was based on a code rertrieved from
 http://www.planetpdf.com/developer/article.asp?ContentID=testing_for_object_types_in_ja.
 */
function isObjAnArray(obj) {

    if (typeof(obj) == 'object') {
        var criterion = obj.constructor.toString().match(/array/i);
        return (criterion != null);
    }
    return false;
}