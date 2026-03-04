<?php
require_once __DIR__ . '/SlugGenerator.php';

class UrlShortener {
    private PDO $pdo;
    private SlugGenerator $slugGenerator;

    public function __construct(PDO $pdo) {
        $this->pdo = $pdo;
        $this->slugGenerator = new SlugGenerator($pdo);
    }

    public function shorten(string $url): array {
        $url = trim($url);
        
        if (!filter_var($url, FILTER_VALIDATE_URL)) {
            throw new InvalidArgumentException('Invalid URL provided');
        }

        $slug = $this->slugGenerator->generate();
        
        $stmt = $this->pdo->prepare(
            "INSERT INTO links (original_url, slug) VALUES (?, ?)"
        );
        $stmt->execute([$url, $slug]);

        return [
            'slug' => $slug,
            'short_url' => BASE_URL . '/' . $slug,
            'mood' => $this->slugGenerator->getRandomMood()
        ];
    }

    public function redirect(string $slug): ?string {
        $stmt = $this->pdo->prepare(
            "SELECT id, original_url FROM links WHERE slug = ?"
        );
        $stmt->execute([$slug]);
        $link = $stmt->fetch();

        if (!$link) {
            return null;
        }

        // Update click count
        $this->pdo->prepare(
            "UPDATE links SET clicks = clicks + 1, last_clicked_at = NOW() WHERE id = ?"
        )->execute([$link['id']]);

        // Record detailed stats
        $this->recordClick($link['id']);

        return $link['original_url'];
    }

    private function recordClick(int $linkId): void {
        $stmt = $this->pdo->prepare(
            "INSERT INTO click_stats (link_id, ip_address, user_agent, referer) VALUES (?, ?, ?, ?)"
        );
        $stmt->execute([
            $linkId,
            $_SERVER['REMOTE_ADDR'] ?? null,
            $_SERVER['HTTP_USER_AGENT'] ?? null,
            $_SERVER['HTTP_REFERER'] ?? null
        ]);
    }

    public function getStats(string $slug): ?array {
        $stmt = $this->pdo->prepare(
            "SELECT * FROM links WHERE slug = ?"
        );
        $stmt->execute([$slug]);
        $link = $stmt->fetch();

        if (!$link) {
            return null;
        }

        // Get recent clicks
        $clickStmt = $this->pdo->prepare(
            "SELECT clicked_at FROM click_stats WHERE link_id = ? ORDER BY clicked_at DESC LIMIT 10"
        );
        $clickStmt->execute([$link['id']]);
        $recentClicks = $clickStmt->fetchAll();

        return [
            'link' => $link,
            'recent_clicks' => $recentClicks
        ];
    }

    public function getRecentLinks(int $limit = 10): array {
        $stmt = $this->pdo->prepare(
            "SELECT slug, clicks, created_at FROM links ORDER BY created_at DESC LIMIT ?"
        );
        $stmt->execute([$limit]);
        return $stmt->fetchAll();
    }

    public function getTotalStats(): array {
        $stmt = $this->pdo->query(
            "SELECT COUNT(*) as total_links, COALESCE(SUM(clicks), 0) as total_clicks FROM links"
        );
        return $stmt->fetch();
    }
}
