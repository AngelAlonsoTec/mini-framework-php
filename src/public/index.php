<?php

$routes = require __DIR__ . '/../routes/web.php';
$requestUri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$route = $routes[$requestUri] ?? null;
// echo __DIR__ . '/../' . $route;
if($route){
    require __DIR__ . '/../' . $route;
}else{
    exit('404 Not Found');
}