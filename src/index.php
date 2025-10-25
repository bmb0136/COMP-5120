<?php
$mysqli = new mysqli("localhost:3307", "bmb0136", "secret", "bmb0136db");
if ($mysqli->connect_error) {
  die("Failed to connect to DB");
}
$mysqli->close();
?>
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>COMP 5120 Project</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@1.0.4/css/bulma.min.css">
  </head>
  <body>
    <section class="section">
      <div class="container">
      </div>
    </section>
  </body>
</html>
