<?php
  function login($url, $username, $password) {
    $data = "username=$username&password=$password";
    $opts = array(
      "http" =>
        array(
        "method"  => "POST",
        "header"  => "Content-type: application/x-www-form-urlencoded",
        "content" => $data
      ),
      "ssl" => array(
        "verify_peer" => false,
        "verify_peer_name" => false
      ),
      'headers' => $http_response_header
    );
    $context = stream_context_create($opts);
    $contents = file_get_contents($url, false, $context);

    foreach ($http_response_header as $value) {
      if (preg_match("/^www-authenticate/i", $value)) {
        $nonce = explode(" ", $value)[2];
        break;
      }
    }
    $to_hash = $username.":".$password.":".$nonce;
    return hash_hmac("sha1", $to_hash, $password, false);
  }
?>