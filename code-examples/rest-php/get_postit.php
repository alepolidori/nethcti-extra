<?php
  function get_postit($url, $username, $token) {
    $opts = array(
      "http" =>
        array(
        "method"  => "GET",
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

    echo $contents;
    echo PHP_EOL;
  }
?>