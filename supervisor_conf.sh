BASEDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

CORES=`echo "$(grep -c processor /proc/cpuinfo)"`

apt-get install -y supervisor

cat <<EOF > /etc/supervisor/conf.d/main.conf
[program:main]
directory=${BASEDIR}
command=antenv/bin/gunicorn -b 0.0.0.0:7000 -w $((CORES*2+1)) --timeout 1200 "app:server"
autostart=true
autorestart=true
stdout_logfile=${BASEDIR}/logs/main.out.log
stderr_logfile=${BASEDIR}/logs/main.err.log
EOF

mkdir -p ${BASEDIR}/logs/supervisor
touch ${BASEDIR}/run/supervisor.sock
touch ${BASEDIR}/run/supervisord.pid

# Create Supervisor web interface credentials file
cat <<EOF > /etc/supervisor/supervisord.conf
[unix_http_server]
file=${BASEDIR}/run/supervisor.sock   ; (the path to the socket file)
chmod=0700                       ; sockef file mode (default 0700)

[supervisord]
logfile=${BASEDIR}/logs/supervisor/supervisord.log ; (main log file;default $CWD/supervisord.log)
pidfile=${BASEDIR}/run/supervisord.pid ; (supervisord pidfile;default supervisord.pid)
childlogdir=${BASEDIR}/logs/supervisor            ; ('AUTO' child log dir, default $TEMP)

; the below section must remain in the config file for RPC
; (supervisorctl/web interface) to work, additional interfaces may be
; added by defining them in separate rpcinterface: sections
[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///${BASEDIR}/run/supervisor.sock ; use a unix:// URL  for a unix socket

; The [include] section can just contain the "files" setting.  This
; setting can list multiple files (separated by whitespace or
; newlines).  It can also contain wildcards.  The filenames are
; interpreted as relative to this file.  Included files *cannot*
; include files themselves.

[include]
files = /etc/supervisor/conf.d/*.conf

EOF

# Start Supervisor and the web interface
supervisord -c /etc/supervisor/supervisord.conf