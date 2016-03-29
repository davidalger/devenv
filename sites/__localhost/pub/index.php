<!doctype html>
<head>
    <meta http-equiv="Content-type" content="text/html; charset=utf-8">
    <title>Hello Vagrant</title>
    <style type="text/css">
      body { text-align: center; padding: 25px 150px; font: 14px "Courier New", Courier, monospace; }
      article { display: block; text-align: justify; width: 876px; margin: 0 auto; }
      pre, code { padding: 0; margin: 0; text-align: center; }
      a { color: black; text-decoration: none; padding: .3em; }
      a:hover { background-color: lightgray; }
      ul li { list-style: none; }
      ul li a { display: block; width: 100%; }
    </style>
</head>
<body>
    <article>
        <pre>
 _   _      _ _        __     __                          _   
| | | | ___| | | ___   \ \   / /_ _  __ _ _ __ __ _ _ __ | |_ 
| |_| |/ _ \ | |/ _ \   \ \ / / _` |/ _` | '__/ _` | '_ \| __|
|  _  |  __/ | | (_) |   \ V / (_| | (_| | | | (_| | | | | |_ 
|_| |_|\___|_|_|\___/     \_/ \__,_|\__, |_|  \__,_|_| |_|\__|
                                    |___/                     
        </pre>
        
        <ul>
        <?php $hosts = explode("\n", file_get_contents('/etc/hosts')) ?>
        <?php foreach ($hosts as $line): ?>
            <?php if (!strlen(trim($line))) continue ?>
            <?php $hostname = trim(explode(' ', $line, 2)[1]) ?>
            <?php if (strpos($hostname, ' ') !== false) continue ?>
            <li><a href="<?= "http://$hostname" ?>"><?= "http://$hostname" ?></a></li>
        <?php endforeach ?>
        </ul>
    </article>
    <footer>
        <a href="http://github.com/davidalger/devenv">GitHub</a> | <a href="http://twitter.com/blackbooker">Twitter</a>
        <p>Copyright &copy; <?= date('Y') ?> by David Alger. Licensed under Open Software License v3.0</p>
    </footer>
</body>
