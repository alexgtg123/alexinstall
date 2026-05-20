#!/bin/bash

REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Api/Client/Servers/DatabaseController.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${REMOTE_PATH}.bak_${TIMESTAMP}"

echo "🚀 Memasang proteksi Anti Intip Database..."

if [ -f "$REMOTE_PATH" ]; then
  mv "$REMOTE_PATH" "$BACKUP_PATH"
  echo "📦 Backup file lama dibuat di $BACKUP_PATH"
fi

mkdir -p "$(dirname "$REMOTE_PATH")"
chmod 755 "$(dirname "$REMOTE_PATH")"

cat > "$REMOTE_PATH" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Api\Client\Servers;

use Illuminate\Support\Facades\Auth;
use Pterodactyl\Models\Server;
use Pterodactyl\Http\Controllers\Api\Client\ClientApiController;
use Pterodactyl\Http\Requests\Api\Client\Servers\Databases\GetDatabasesRequest;

class DatabaseController extends ClientApiController
{
    public function index(GetDatabasesRequest $request, Server $server): array
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, 'Akses Detail Database Diblokir');
        }

        return [];
    }
}
EOF

chmod 644 "$REMOTE_PATH"
echo "✅ Protect Anti Intip Database berhasil dipasang!"
