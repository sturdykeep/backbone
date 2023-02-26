
var wsReady = false;
var socket = null;
var lastHost = null;
var retryCounter = 5;
var msg = [];
onmessage = function (e) {
    if ((typeof (e.data) == "string" || lastHost != null) && wsReady == false && retryCounter > 0) {
        if (lastHost == null) {
            lastHost = e.data.toString();
        }
        //Setup the WS connection
        socket = new WebSocket(lastHost);
        socket.onopen = function () {
            console.log(`Socket setup done, connected to ${lastHost}`);
            while (msg.length > 0) {
                socket.send(JSON.stringify(msg.pop()));
            }
        };
        socket.onclose = function () {
            console.error(`WS connection to ${lastHost} failed. Make sure Perfmon is running! Retrying for ${retryCounter} times.`);
            retryCounter--;
            wsReady = false;
            socket = null;
        };
        wsReady = true;
    }
    //Handle log data
    let data = e.data;
    if (typeof (data) == "object") {
        if (socket.readyState !== 1) {
            msg.push(data)
        } else {
            socket.send(JSON.stringify(data));
        }
    }



}