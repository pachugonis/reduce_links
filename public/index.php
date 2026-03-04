<?php
require_once __DIR__ . '/../includes/config.php';
require_once __DIR__ . '/../includes/UrlShortener.php';

$shortener = new UrlShortener($pdo);
$message = null;
$result = null;
$stats = null;
$error = null;

// Handle form submission
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['url'])) {
        try {
            $result = $shortener->shorten($_POST['url']);
        } catch (Exception $e) {
            $error = $e->getMessage();
        }
    }
}

// Handle stats view
if (isset($_GET['stats'])) {
    $stats = $shortener->getStats($_GET['stats']);
}

// Get overall stats
$totalStats = $shortener->getTotalStats();
$recentLinks = $shortener->getRecentLinks(5);
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Funky Links - URL Shortener with Character</title>
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
            <p class="tagline">URL shortener with <span class="highlight">character</span></p>
        </header>

        <main class="main">
            <section class="shorten-section">
                <form method="POST" class="shorten-form">
                    <div class="input-group">
                        <input 
                            type="url" 
                            name="url" 
                            placeholder="Paste your looong URL here..."
                            required
                            class="url-input"
                        >
                        <button type="submit" class="submit-btn">
                            <span>Shorten!</span>
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M5 12h14M12 5l7 7-7 7"/>
                            </svg>
                        </button>
                    </div>
                </form>

                <?php if ($error): ?>
                <div class="message error">
                    <span class="message-icon">:(</span>
                    <?= htmlspecialchars($error) ?>
                </div>
                <?php endif; ?>

                <?php if ($result): ?>
                <div class="result">
                    <div class="result-header">
                        <span class="mood"><?= htmlspecialchars($result['mood']) ?></span>
                    </div>
                    <div class="result-url">
                        <input 
                            type="text" 
                            value="<?= htmlspecialchars($result['short_url']) ?>" 
                            readonly 
                            class="result-input"
                            id="shortUrl"
                        >
                        <button onclick="copyUrl()" class="copy-btn" title="Copy to clipboard">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <rect x="9" y="9" width="13" height="13" rx="2" ry="2"/>
                                <path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/>
                            </svg>
                        </button>
                    </div>
                    <div class="result-actions">
                        <a href="?stats=<?= htmlspecialchars($result['slug']) ?>" class="stats-link">View Stats</a>
                    </div>
                </div>
                <?php endif; ?>
            </section>

            <?php if ($stats): ?>
            <section class="stats-section">
                <h2>Stats for <span class="slug-name"><?= htmlspecialchars($stats['link']['slug']) ?></span></h2>
                <div class="stats-grid">
                    <div class="stat-card">
                        <div class="stat-value"><?= number_format($stats['link']['clicks']) ?></div>
                        <div class="stat-label">Total Clicks</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value"><?= date('M j', strtotime($stats['link']['created_at'])) ?></div>
                        <div class="stat-label">Created</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value"><?= $stats['link']['last_clicked_at'] ? date('M j', strtotime($stats['link']['last_clicked_at'])) : 'Never' ?></div>
                        <div class="stat-label">Last Click</div>
                    </div>
                </div>
                <div class="original-url">
                    <strong>Destination:</strong> 
                    <a href="<?= htmlspecialchars($stats['link']['original_url']) ?>" target="_blank" rel="noopener">
                        <?= htmlspecialchars(strlen($stats['link']['original_url']) > 60 ? substr($stats['link']['original_url'], 0, 60) . '...' : $stats['link']['original_url']) ?>
                    </a>
                </div>
            </section>
            <?php endif; ?>

            <section class="overview-section">
                <div class="overview-stats">
                    <div class="overview-stat">
                        <span class="overview-value"><?= number_format($totalStats['total_links']) ?></span>
                        <span class="overview-label">Links Created</span>
                    </div>
                    <div class="overview-divider"></div>
                    <div class="overview-stat">
                        <span class="overview-value"><?= number_format($totalStats['total_clicks']) ?></span>
                        <span class="overview-label">Total Clicks</span>
                    </div>
                </div>
            </section>

            <?php if (!empty($recentLinks)): ?>
            <section class="recent-section">
                <h3>Recent Funky Links</h3>
                <div class="recent-links">
                    <?php foreach ($recentLinks as $link): ?>
                    <div class="recent-link">
                        <span class="recent-slug"><?= htmlspecialchars($link['slug']) ?></span>
                        <span class="recent-clicks"><?= number_format($link['clicks']) ?> clicks</span>
                        <a href="?stats=<?= htmlspecialchars($link['slug']) ?>" class="recent-stats-btn">Stats</a>
                    </div>
                    <?php endforeach; ?>
                </div>
            </section>
            <?php endif; ?>
        </main>

        <footer class="footer">
            <p>Made with <span class="heart">+</span> and a sense of humor</p>
        </footer>
    </div>

    <script>
        function copyUrl() {
            const input = document.getElementById('shortUrl');
            input.select();
            input.setSelectionRange(0, 99999);
            navigator.clipboard.writeText(input.value);
            
            const btn = document.querySelector('.copy-btn');
            btn.innerHTML = '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>';
            setTimeout(() => {
                btn.innerHTML = '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1"/></svg>';
            }, 2000);
        }
    </script>
</body>
</html>
