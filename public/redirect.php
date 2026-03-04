<?php
require_once __DIR__ . '/../includes/config.php';
require_once __DIR__ . '/../includes/UrlShortener.php';

$slug = $_GET['slug'] ?? '';

if (empty($slug)) {
    header('Location: /');
    exit;
}

$shortener = new UrlShortener($pdo);
$url = $shortener->redirect($slug);

if ($url) {
    header('HTTP/1.1 301 Moved Permanently');
    header('Location: ' . $url);
    exit;
}

// Not found - show 404
http_response_code(404);
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Link Not Found - Funky Links</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Space+Grotesk:wght@500;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="/assets/css/style.css">
</head>
<body>
    <div class="container">
        <header class="header">
            <div class="logo">
                <span class="logo-icon">~</span>
                <h1>Funky Links</h1>
            </div>
        </header>
        <main class="main">
            <section class="stats-section" style="text-align: center;">
                <h2 style="font-size: 4rem; margin-bottom: 1rem;">404</h2>
                <p style="color: var(--gray-500); margin-bottom: 1.5rem;">
                    Oops! This funky link doesn't exist... yet!
                </p>
                <a href="/" class="submit-btn" style="display: inline-flex; text-decoration: none;">
                    Create a new one
                </a>
            </section>
        </main>
    </div>
</body>
</html>
