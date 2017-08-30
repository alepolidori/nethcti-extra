#!/bin/env php
<?php
  error_reporting(E_ERROR | E_PARSE);

  if (count($argv) < 6) {
    echo "use:\t$argv[0] <hostname> <username> <password> <text> <dest_user>\n".
         "\te.g. $argv[0] 192.168.5.212 ale pass \"some text\" andrea\n";
    exit(1);
  }

  $server = $argv[1];
  $username = $argv[2];
  $password = $argv[3];
  $text = $argv[4];
  $dest = $argv[5];
  $url_login = "https://$server/webrest/authentication/logi";
  $url_logout = "https://$server/webrest/authentication/logout";
  $url_postit = "https://$server/webrest/postit/create";
  
  $token = login($url_login, $username, $password);
  if ($token == undefined) {
    echo "[$argv[0]] - error: login failed\n";
    exit(1);
  }
  
  $res = create_postit($url_postit, $username, $token, $text, $dest);
  if (!$res) { echo "[$argv[0]] - error: post-it creation failed\n"; }
  
  $res = logout($url_logout, $username, $token);
  if ($res) { exit(0); }
  else {
    echo "[$argv[0]] - error: logout failed\n";
    exit(1);
  }

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
        $nonce = explode(" ", $value);
        $nonce = $nonce[2];
        break;
      }
    }
    if (!isset($nonce)) { return undefined; }

    $to_hash = $username.":".$password.":".$nonce;
    return hash_hmac("sha1", $to_hash, $password, false);
  }

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