<?php
$mysqli = new mysqli("localhost:3307", "bmb0136", "secret", "bmb0136db");
if ($mysqli->connect_error) {
  die("Failed to connect to DB");
}
$mysqli->close();
?>
