<?php
$host = "127.0.0.1";
$port = "8080";

// Create TCP socket
$socket = socket_create(AF_INET, SOCK_STREAM, SOL_TCP);
socket_set_option($socket, SOL_SOCKET, SO_REUSEADDR, null);
socket_bind($socket, 0, $port);

// Set binded socket to listen the port
socket_listen($socket);

// Clients list who connect in
$clients = array($socket);
$users = array();

// The loop to repeat listen request
while(true){
    // The changed socket will return by $changed in this function
    // Select will stock until a client connect
    $changes = $clients;
    socket_select($changes, $write, $expect, null); 

    // If there is a new connection
    foreach($changes as $sock){
        if($sock == $socket){ // If a new client connect in
            $client = socket_accept($socket);
            $clients[] = $client; // Push new client to array

            // Give user a id
            $id = uniqid();
            $users[$id] = array(
                'socket' => $client,
                'handshake' => false
            );
        }else{
            $len = 0;
            $buffer='';
            
            do{
                $l = socket_recv($sock, $data, 1000, 0);
                $len += $l;
                $buffer .= $data;
            }while($l == 1000);

            $id = search_user($sock, $users);

            // If len < 7, then see it as close connection
            if($len < 7){
                close($id, $users, $socket, $clients);
                continue;
            }

            // If this user doesn't handshake then do it
            if(!$users[$id]['handshake']){
                handshake($id, $buffer, $users);
            }else{
                // Here is represent that user want to send a message
                $msg = "Socket test";
                $buffer = decode($buffer);
                echo "Client $id sends msg: $buffer\n";
                send($users[$id]['socket'], $msg);
            
            }
            // echo($buffer);

        }
    }
}

function handshake($id, $buffer, &$users){
    // Extract Key
    $buf = substr($buffer, strpos($buffer, 'Sec-WebSocket-Key:') + 18); 
    $key = trim(substr($buf, 0 , strpos($buf, "\r\n")));

    // Encrypt key for handshake, below follow the protocol
    $enc_key = base64_encode(sha1($key."258EAFA5-E914-47DA-95CA-C5AB0DC85B11", true));

    // Compose response message
    $response_msg = "HTTP/1.1 101 Switching Protocols\r\n";
    $response_msg .= "Upgrade: websocket\r\n";
    $response_msg .= "Sec-WebSocket-Version: 13\r\n";
    $response_msg .= "Connection: Upgrade\r\n";
    $response_msg .= "Sec-WebSocket-Accept: " . $enc_key . "\r\n\r\n";

    socket_write($users[$id]['socket'], $response_msg, strlen($response_msg));

    $users[$id]['handshake'] = true;

    echo "Client $id is connected.\n";

    return true;
}

function close($id, &$users, &$socket, &$clients){
    socket_close($users[$id]['socket']);
    unset($users[$id]);

    // Redefine socket pool
    $clients = array($socket);
    foreach($users as $v){
        $clients[] = $v['socket'];
    }
}

function decode($buffer){
    $len = $masks = $data = $decoded = null;
    $len = ord($buffer[1]) & 127;

    if ($len === 126) {
        $masks = substr($buffer, 4, 4);
        $data = substr($buffer, 8);
    } else if ($len === 127) {
        $masks = substr($buffer, 10, 4);
        $data = substr($buffer, 14);
    } else {
        $masks = substr($buffer, 2, 4);
        $data = substr($buffer, 6);
    }
    for ($index = 0; $index < strlen($data); $index++) {
        $decoded .= $data[$index] ^ $masks[$index % 4];
    }
    return $decoded;
}

// 返回幀資訊處理
function frame($s){
    $a = str_split($s, 125);
    if (count($a) == 1) {
        return "x81" . chr(strlen($a[0])) . $a[0];
    }
    $ns = "";
    foreach ($a as $o) {
        $ns .= "x81" . chr(strlen($o)) . $o;
    }
    return $ns;
}

// 返回資料
function send($socket, $msg)
{
    $msg = frame($msg);
    socket_write($socket, $msg, strlen($msg));
}

function search_user($sock, &$array){
    foreach($array as $key => $value){
        if($value['socket'] == $sock){
            return $key;
        }
    }
    return null;
}
