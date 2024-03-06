BASEDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

sudo apt-get install -y nginx

cat <<EOF > /etc/nginx/proxy_params
proxy_set_header Host \$http_host;
proxy_set_header X-Real-IP \$remote_addr;
proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto \$scheme;
proxy_set_header Connection "Keep-Alive";
proxy_set_header Proxy-Connection "Keep-Alive";
EOF

cat <<EOF > /etc/nginx/sites-enabled/app
proxy_cache_path /tmp/cache levels=1:2 keys_zone=cache:1m max_size=500m inactive=60m use_temp_path=off;

upstream backend {
    keepalive 100;
    server localhost:7000 max_fails=2 fail_timeout=60s;
}

server {
  listen 8000;
  proxy_intercept_errors on;

  proxy_read_timeout 60;
  proxy_connect_timeout 60;
  proxy_send_timeout 60;
  proxy_headers_hash_max_size 512;
  proxy_headers_hash_bucket_size 128;

  location = /robots933456.txt {
    access_log off;
    add_header 'Content-Type' 'application/json';
    return 200 '{"status":"UP", "message":"hello robots"}';
  }

  location = /health_check {
    access_log off;
    add_header 'Content-Type' 'application/json';
    return 200 '{"status":"UP"}';
  }

  location /assets {
    expires 1y;
    add_header Cache-Control "public; max-age=30672000";
    gzip_static on;
    alias ${BASEDIR}/assets;
  }

  location /static {
    expires 120m;
    add_header Cache-Control "public";
    gzip_static on;
    alias ${BASEDIR}/static;
  }

  location /_dash-component-suites {
    expires 1y;
    proxy_cache cache;
    proxy_cache_lock on;
    proxy_cache_lock_age 30s;
    proxy_cache_lock_timeout 30s;
    proxy_cache_valid 200 1y;
    gzip_static on;
    proxy_buffering on;
    uwsgi_buffering off;
    proxy_redirect off;
    proxy_http_version 1.1;
    add_header Cache-Control "public, max-age=30672000";
    proxy_pass http://backend;
    include /etc/nginx/proxy_params;
  }

  location /_dash-update-component {
    proxy_pass \$backend;
    proxy_redirect off;
    proxy_http_version 1.1;
    proxy_cache cache;
    proxy_cache_lock on;
    proxy_cache_lock_age 30s;
    proxy_cache_lock_timeout 30s;
    proxy_cache_valid 200 1m;
    proxy_buffering on;
    include /etc/nginx/proxy_params;
  }

  location / {
    proxy_pass http://backend;
    proxy_redirect off;
    proxy_http_version 1.1;
    proxy_cache cache;
    proxy_cache_lock on;
    proxy_cache_lock_age 30s;
    proxy_cache_lock_timeout 30s;
    proxy_cache_valid 200 1m;
    proxy_buffering on;
    include /etc/nginx/proxy_params;
  }

}
EOF

service nginx restart