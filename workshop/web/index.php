<?php
    header("refresh: 3;");
?>
<html>
<body bgColor=pink>
<h1>Hola1</h1>
<?php
echo 'UNAME: ' . php_uname() . '<br/>';
echo 'HOSTNAME: ' . gethostname() .  '<br/>';
echo 'OS: ' . PHP_OS .  '<br/>';
?>
</body>
</html>
