<?php header("Cache-Control: no-cache, must-revalidate"); ?>
<html>
	<head>
		<title>Application Gateway + App Service Environment test</title>
	</head>
	<body>
		<h2><?php echo date("Y-m-d h:i:sa"); ?></h2>
		<h3>Request details</h3>
		<ul>
			<li>HTTP_HOST: <?= $_REQUEST['HTTP_HOST']; ?></li>
			<li>REMOTE_ADDR: <?= $_REQUEST['REMOTE_ADDR']; ?></li>
			<li>REMOTE_HOST: <?= $_REQUEST['REMOTE_HOST']; ?></li>
			<li>WEBSITE_HOSTNAME: <?= $_REQUEST['WEBSITE_HOSTNAME']; ?></li>
			<li>HTTP_X_FORWARDED_FOR: <?= $_REQUEST['HTTP_X_FORWARDED_FOR']; ?></li>
			<li>HTTPS: <?= $_REQUEST['HTTPS']; ?></li>
			<li>HTTPS_SERVER_ISSUER: <?= $_REQUEST['HTTPS_SERVER_ISSUER']; ?></li>
			<li>HTTPS_SERVER_SUBJECT: <?= $_REQUEST['HTTPS_SERVER_SUBJECT']; ?></li>
		</ul>
	</body>
</html>