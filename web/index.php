<?php
    header("refresh: 3;");
?>
<html>
<body bgColor=withe>
<h1>Hola</h1>
<?php
echo 'UNAME: ' . php_uname() . '<br/>';
echo 'HOSTNAME: ' . gethostname() .  '<br/>';
echo 'OS: ' . PHP_OS .  '<br/>';
?>
</body>
</html>
