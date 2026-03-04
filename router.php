<?php
/**
 * PHP Built-in Server Router
 * Usage: php -S localhost:8080 router.php
 */

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

// Serve static files
if ($uri !== '/' && file_exists(__DIR__ . '/public' . $uri)) {
    return false;
}

// Serve assets
if (preg_match('/^\/assets\//', $uri)) {
    $file = __DIR__ . $uri;
    if (file_exists($file)) {
        $ext = pathinfo($file, PATHINFO_EXTENSION);
        $mimes = [
            'css' => 'text/css',
            'js' => 'application/javascript',
            'png' => 'image/png',
            'jpg' => 'image/jpeg',
            'gif' => 'image/gif',
            'svg' => 'image/svg+xml',
            'woff2' => 'font/woff2',
        ];
        if (isset($mimes[$ext])) {
            header('Content-Type: ' . $mimes[$ext]);
        }
        readfile($file);
        return true;
    }
}

// Route to index or redirect
if ($uri === '/' || $uri === '/index.php') {
    require __DIR__ . '/public/index.php';
} elseif (preg_match('/^\/([a-zA-Z0-9\-]+)$/', $uri, $matches)) {
    $_GET['slug'] = $matches[1];
    require __DIR__ . '/public/redirect.php';
} else {
    require __DIR__ . '/public/index.php';
}
