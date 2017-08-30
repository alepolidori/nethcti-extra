<?php
  function create_postit($url, $username, $token, $text, $dest) {
    $opts = array(
      "http" =>
        array(
        "method"  => "POST",
        "header"  => "Content-type: application/x-www-form-urlencoded\r\n".
                     "Authorization: $username:$token",
        "content" => "text=$text&recipient=$dest"
      ),
      "ssl" => array(
        "verify_peer" => false,
        "verify_peer_name" => false
      ),
      'headers' => $http_response_header
    );
    $context = stream_context_create($opts);
    $contents = file_get_contents($url, false, $context);

    if (preg_match("/^HTTP\/1.1 201 Created/i", $http_response_header[0])) { return true; }
    else { return false; }
  }
?>