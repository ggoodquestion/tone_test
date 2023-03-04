var socket = false;

$("#slmtk0").submit(function (event) {
    event.preventDefault();

    // connectSocket();

    var fd = new FormData();
    var file1 = $('#txtfile')[0].files[0];
    var file2 = $('#wavfile')[0].files[0];
    fd.append('txtfile', file1);
    fd.append('wavfile', file2);

    $.ajax({
        url: "/slmtk/upload.php",
        data: fd,
        cache: false,
        processData: false,
        contentType: false,
        type: 'post',
        success: function (data) {
            if(data == "success")showSuccAlert(data);
            else showFailAlert(data);
        },
        error: function (data) {
            showFailAlert(data);
        }
    });
});

$("#s1").click(function(){
    socket.send("Hello");
});

function connectSocket(){
    var url = "ws://120.126.151.132:8083";
    var port = 8083;
    //var socket = false; // Handshake flag

    socket = new WebSocket(url);

    socket.onopen = function(){
        if(socket.readyState == 1){
            alert("握手成功");
        }
        socket.send("hello\r\n\r\n");
    }

    socket.onclose = function(){
        socket = false;
        alert("握手失敗");
    }

    socket.onmessage = function(msg){
        alert(msg);
    }
}

function showSuccAlert(msg){
    $("#show-stat").removeClass("alert-danger");
    $("#show-stat").addClass("alert-success");
    $("#show-stat").text(msg);
}

function showFailAlert(msg){
    $("#show-stat").removeClass("alert-success");
    $("#show-stat").addClass("alert-danger");
    $("#show-stat").text(msg);
}