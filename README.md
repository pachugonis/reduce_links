# 🔗 Reduce Links — URL Shortener with Character

A fun and funky URL shortener built with PHP and MySQL. No frameworks, no bloat — just clean, simple code that gets the job done with style.

![PHP](https://img.shields.io/badge/PHP-8.0+-777BB4?logo=php&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?logo=mysql&logoColor=white)
![Apache](https://img.shields.io/badge/Apache-2.4-D22128?logo=apache&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## ✨ Features

- 🎨 **Funky Design** — Modern, playful UI with smooth animations
- ⚡ **Fast & Lightweight** — Pure PHP, no heavy frameworks
- 📊 **Click Statistics** — Track clicks, referrers, and user agents
- 🔒 **Clean URLs** — Apache mod_rewrite for pretty slugs
- 🎯 **Slug Generation** — Unique, memorable short links
- 📱 **Responsive** — Works great on mobile and desktop

## 🚀 Quick Start

### Requirements

- PHP 8.0+
- MySQL 8.0+
- Apache with mod_rewrite
- Composer (optional)

### Manual Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/reduce_links.git
   cd reduce_links
   ```

2. **Create the database**
   ```bash
   mysql -u root -p < database.sql
   ```

3. **Configure the application**
   ```bash
   cp includes/config.php includes/config.php.example
   # Edit includes/config.php with your database credentials
   ```

4. **Set permissions**
   ```bash
   chown -R www-data:www-data .
   chmod -R 755 .
   ```

5. **Configure Apache**
   
   Point your virtual host to the `public/` directory:
   ```apache
   <VirtualHost *:80>
       ServerName your-domain.com
       DocumentRoot /var/www/reduce_links/public
       
       <Directory /var/www/reduce_links/public>
           AllowOverride All
           Require all granted
       </Directory>
   </VirtualHost>
   ```

6. **Enable mod_rewrite**
   ```bash
   sudo a2enmod rewrite
   sudo systemctl restart apache2
   ```

### 🖥️ Automatic VPS Installation (Ubuntu 24)

For quick deployment on a fresh Ubuntu 24 server:

1. **Download the release files**
   ```bash
   wget https://github.com/yourusername/reduce_links/releases/download/v1.0/reduce_links.zip
   wget https://github.com/yourusername/reduce_links/releases/download/v1.0/install.sh
   ```

2. **Run the installer**
   ```bash
   chmod +x install.sh
   sudo ./install.sh
   ```

The script will:
- Install Apache, PHP, and MySQL
- Generate secure random passwords
- Configure the database automatically
- Set up SSL with Let's Encrypt
- Configure the firewall

## 📁 Project Structure

```
reduce_links/
├── assets/
│   └── css/
│       └── style.css          # Main stylesheet
├── includes/
│   ├── config.php             # Database configuration
│   ├── SlugGenerator.php      # Unique slug generator
│   └── UrlShortener.php       # Core shortening logic
├── public/
│   ├── .htaccess              # Apache rewrite rules
│   ├── index.php              # Main application
│   └── redirect.php           # Slug redirect handler
├── database.sql               # Database schema
├── install.sh                 # VPS installation script
└── router.php                 # PHP dev server router
```

## 🛠️ Development

### Using PHP Built-in Server

```bash
php -S localhost:8080 router.php
```

Then open http://localhost:8080 in your browser.

### Database Schema

**links table**
| Column | Type | Description |
|--------|------|-------------|
| id | INT | Primary key |
| original_url | TEXT | Full URL |
| slug | VARCHAR(100) | Short identifier |
| clicks | INT | Click counter |
| created_at | TIMESTAMP | Creation time |
| last_clicked_at | TIMESTAMP | Last click time |

**click_stats table**
| Column | Type | Description |
|--------|------|-------------|
| id | INT | Primary key |
| link_id | INT | Foreign key to links |
| clicked_at | TIMESTAMP | Click time |
| ip_address | VARCHAR(45) | Visitor IP |
| user_agent | TEXT | Browser info |
| referer | TEXT | Referring page |

## 🔧 Configuration

Edit `includes/config.php`:

```php
define('DB_HOST', 'localhost');
define('DB_NAME', 'url_shortener');
define('DB_USER', 'your_db_user');
define('DB_PASS', 'your_db_password');
define('BASE_URL', 'https://your-domain.com');
```

## 📝 API Usage

### Create Short URL

```bash
curl -X POST -d "url=https://example.com/very/long/url" https://your-domain.com
```

### View Stats

Visit `https://your-domain.com/?stats=YOUR_SLUG`

## 🛡️ Security

- Prepared statements for all database queries
- Input validation and sanitization
- XSS protection with htmlspecialchars
- SQL injection prevention via PDO
- Optional: Fail2Ban integration for brute force protection

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Fonts: [Inter](https://fonts.google.com/specimen/Inter) & [Space Grotesk](https://fonts.google.com/specimen/Space+Grotesk)
- Icons: Custom SVG

---

Made with 💜 and a sense of humor
