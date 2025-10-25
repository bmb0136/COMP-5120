<?php
$sql_error = "";
$query = "";

if (isset($_POST["query"]) && trim(strlen($_POST["query"])) > 0) {
  $query = $_POST["query"];

  if (str_contains(strtolower($query), "drop")) {
    $sql_error = "DROP statements not allowed";
  } else {

    $mysqli = new mysqli("localhost:3307", "bmb0136", "secret", "bmb0136db");
    try {
      $result = $mysqli->query($query);
      $rows = $result === true ? 0 : $result->num_rows;
    } catch (mysqli_sql_exception $e) {
      $sql_error = $e->getMessage();
    }

    $mysqli->close();
  }
}
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
      <div class="container box">
        <form method="post" id="mainForm">
          <div class="field">
            <label class="label">Query</label>
            <textarea id="qryBox" class="textarea <?php echo strlen($sql_error) || ($_SERVER["REQUEST_METHOD"] == "POST" && strlen($query) == 0) > 0 ? "is-danger" : ""; ?>" placeholder="Insert SQL Query" rows=10 name="query"><?php echo $query; ?></textarea>
            <?php
            if (strlen($sql_error) > 0) {
              echo '<p id="errorMsg" class="help is-danger">' . htmlspecialchars($sql_error) . '</p>';
            } else if ($_SERVER["REQUEST_METHOD"] == "POST" && strlen($query) == 0) {
              echo '<p id="errorMsg" class="help is-danger">Please provide a query</p>';
            }
            ?>
          </div>
          <hr />
          <div class="columns">
            <div class="column">
              <button class="button is-primary is-fullwidth is-large" type="submit">Execute</button>
            </div>
            <div class="column">
              <button class="button is-link is-fullwidth is-large" id="resetBtn">Reset</button>
            </div>
          </div>
        </form>
      </div>
      <?php if (isset($result) && $rows > 0): ?>
      <div id="output" class="container box">
        <table class="table is-fullwidth is-striped">
          <thead>
            <tr>
              <?php
                while ($field = $result->fetch_field()) {
                  echo "<td><b>" . $field->name . "</b></td>";
                }
              ?>
            </tr>
          </thead>
          <tbody>
            <?php
            while ($row = $result->fetch_row()) {
              echo "<tr>";
              for ($i = 0; $i < sizeof($row); $i++) {
                  echo "<td>" . $row[$i] . "</td>";
              }
              echo "</tr>";
            }
            ?>
          </tbody>
        </table>
      </div>
      <?php endif; ?>
    </section>
    <script type="text/javascript">
      (function () {
        let form = document.getElementById("mainForm");
        let resetBtn = document.getElementById("resetBtn");
        let qryBox = document.getElementById("qryBox");
        let errorMsg = document.getElementById("errorMsg");
        let output = document.getElementById("output");

        resetBtn.addEventListener("click", function (e) {
          e.preventDefault();
          if (errorMsg) {
            errorMsg.remove();
          }
          if (output) {
            output.remove();
          }
          qryBox.classList.remove("is-danger");
          qryBox.value = "";
          qryBox.focus();
        });
        qryBox.addEventListener("keydown", function (e) {
          if (e.ctrlKey && e.key == "Enter") {
            form.submit();
          }
        });

        document.addEventListener("DOMContentLoaded", function() {
          qryBox.focus();
          qryBox.selectionStart = qryBox.value.length;
        });
      })();
    </script>
  </body>
</html>
