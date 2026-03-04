-- Database schema for URL Shortener with Character
CREATE DATABASE IF NOT EXISTS url_shortener CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE url_shortener;

CREATE TABLE IF NOT EXISTS links (
    id INT AUTO_INCREMENT PRIMARY KEY,
    original_url TEXT NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    clicks INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_clicked_at TIMESTAMP NULL,
    INDEX idx_slug (slug),
    INDEX idx_created (created_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS click_stats (
    id INT AUTO_INCREMENT PRIMARY KEY,
    link_id INT NOT NULL,
    clicked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent TEXT,
    referer TEXT,
    FOREIGN KEY (link_id) REFERENCES links(id) ON DELETE CASCADE,
    INDEX idx_link_id (link_id),
    INDEX idx_clicked (clicked_at)
) ENGINE=InnoDB;
