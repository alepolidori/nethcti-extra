<?php
function logout($url, $username, $token) {
    $opts = array(
      "http" =>
        array(
        "method"  => "POST",
        "header"  => "Content-type: application/x-www-form-urlencoded\r\n".
                     "Authorization: $username:$token"
      ),
      "ssl" => array(
        "verify_peer" => false,
        "verify_peer_name" => false
      ),
      'headers' => $http_response_header
    );
    $context = stream_context_create($opts);
    $contents = file_get_contents($url, false, $context);

    if (preg_match("/^HTTP\/1.1 200 OK/i", $http_response_header[0])) { return true; }
    else { return false; }
  }
?>