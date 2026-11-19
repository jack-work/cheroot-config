echo uid=$(id -u)
echo pwd=$(pwd)
test -S /run/figaro/angelus.sock && echo DOOR-VISIBLE || echo door-absent
{ echo from-tool > written; } 2>/dev/null && echo wrote || echo write-refused
