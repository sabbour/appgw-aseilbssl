<?php header("Cache-Control: no-cache, must-revalidate"); ?>
<html>
	<head>
		<title>Application Gateway + App Service Environment test</title>
	</head>
	<body>
		<h2><?php echo date("Y-m-d h:i:sa"); ?></h2>
		<h3>Request details</h3>
		<ul>
			<li>HTTP_HOST: <?= $_SERVER['HTTP_HOST']; ?></li>
			<li>REMOTE_ADDR: <?= $_SERVER['REMOTE_ADDR']; ?></li>
			<li>REMOTE_HOST: <?= $_SERVER['REMOTE_HOST']; ?></li>
			<li>WEBSITE_HOSTNAME: <?= $_SERVER['WEBSITE_HOSTNAME']; ?></li>
			<li>HTTP_X_FORWARDED_FOR: <?= $_SERVER['HTTP_X_FORWARDED_FOR']; ?></li>
			<li>HTTP_X_FORWARDED_PROTO: <?= $_SERVER['HTTP_X_FORWARDED_PROTO']; ?></li>
			<li>HTTP_X_FORWARDED_PORT: <?= $_SERVER['HTTP_X_FORWARDED_PORT']; ?></li>
			<li>HTTPS: <?= $_SERVER['HTTPS']; ?></li>
			<li>HTTPS_SERVER_ISSUER: <?= $_SERVER['HTTPS_SERVER_ISSUER']; ?></li>
			<li>HTTPS_SERVER_SUBJECT: <?= $_SERVER['HTTPS_SERVER_SUBJECT']; ?></li>
		</ul>
	</body>
</html>