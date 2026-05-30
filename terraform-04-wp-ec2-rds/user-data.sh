#!/bin/bash
set -euxo pipefail

# ─── System update and package installation ───────────────────────────────────
dnf update -y

# Install Apache, PHP 8.1, and MySQL client only (no local DB server)
dnf install -y \
  httpd \
  php \
  php-mysqlnd \
  php-fpm \
  php-json \
  php-mbstring \
  php-xml \
  php-gd \
  mariadb105 \
  wget \
  curl

# ─── Write EC2 health check file (proves bootstrap completed) ─────────────────
cat > /var/www/html/health.html <<'EOF'
<!DOCTYPE html>
<html><body>
<h1>EC2 Bootstrap OK</h1>
<p>Apache is running and user_data completed successfully.</p>
</body></html>
EOF

# ─── Wait for RDS to accept connections ───────────────────────────────────────
# The bootstrap runs immediately when EC2 starts; RDS may take 5-10 min.
DB_HOST="${db_host}"
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASS="${db_password}"

echo "Waiting for RDS at $DB_HOST to accept MySQL connections..."
for i in $(seq 1 60); do
  if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "SELECT 1;" "$DB_NAME" 2>/dev/null; then
    echo "RDS is accepting connections after $i attempts."
    break
  fi
  echo "Attempt $i: RDS not ready yet, sleeping 10s..."
  sleep 10
done

# ─── Write PHP RDS health check file ──────────────────────────────────────────
cat > /var/www/html/db-health.php <<PHPEOF
<?php
\$host = "${db_host}";
\$db   = "${db_name}";
\$user = "${db_user}";
\$pass = "${db_password}";

try {
    \$pdo = new PDO("mysql:host=\$host;dbname=\$db;charset=utf8", \$user, \$pass);
    \$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    \$stmt = \$pdo->query("SELECT 1 AS db_ok");
    \$row  = \$stmt->fetch(PDO::FETCH_ASSOC);
    echo json_encode([
        "status"   => "ok",
        "db_host"  => \$host,
        "db_name"  => \$db,
        "db_ok"    => \$row["db_ok"],
        "message"  => "PHP successfully connected to RDS MySQL"
    ]);
} catch (PDOException \$e) {
    http_response_code(500);
    echo json_encode([
        "status"  => "error",
        "db_host" => \$host,
        "message" => \$e->getMessage()
    ]);
}
PHPEOF

# ─── Download and configure WordPress ─────────────────────────────────────────
cd /tmp
wget -q https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp -r wordpress/* /var/www/html/

# Configure WordPress to connect to RDS
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

sed -i "s/database_name_here/${db_name}/"    /var/www/html/wp-config.php
sed -i "s/username_here/${db_user}/"         /var/www/html/wp-config.php
sed -i "s/password_here/${db_password}/"     /var/www/html/wp-config.php
# Use RDS endpoint — NOT localhost
sed -i "s/localhost/${db_host}/"             /var/www/html/wp-config.php

# Generate unique auth keys/salts
SALT=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/ 2>/dev/null || echo "# Salt fetch failed")
# Remove placeholder lines and insert real salts
sed -i "/AUTH_KEY/d;/SECURE_AUTH_KEY/d;/LOGGED_IN_KEY/d;/NONCE_KEY/d" /var/www/html/wp-config.php
sed -i "/AUTH_SALT/d;/SECURE_AUTH_SALT/d;/LOGGED_IN_SALT/d;/NONCE_SALT/d" /var/www/html/wp-config.php
echo "$SALT" >> /var/www/html/wp-config.php

# ─── Fix file ownership and permissions ───────────────────────────────────────
chown -R apache:apache /var/www/html/
chmod -R 755 /var/www/html/
chmod 640 /var/www/html/wp-config.php

# ─── Enable and start Apache ──────────────────────────────────────────────────
systemctl enable httpd
systemctl start httpd

echo "Bootstrap complete. WordPress is ready at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/"
