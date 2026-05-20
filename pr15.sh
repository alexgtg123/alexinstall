#!/bin/bash

REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Api/Client/Servers/PowerController.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${REMOTE_PATH}.bak_${TIMESTAMP}"

echo "🚀 Memasang proteksi Anti Rusuh Server..."

if [ -f "$REMOTE_PATH" ]; then
  mv "$REMOTE_PATH" "$BACKUP_PATH"
  echo "📦 Backup file lama dibuat di $BACKUP_PATH"
fi

mkdir -p "$(dirname "$REMOTE_PATH")"
chmod 755 "$(dirname "$REMOTE_PATH")"

cat > "$REMOTE_PATH" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Api\Client\Servers;

use Illuminate\Http\Response;
use Illuminate\Support\Facades\Auth;
use Pterodactyl\Models\Server;
use Pterodactyl\Repositories\Wings\DaemonPowerRepository;
use Pterodactyl\Http\Controllers\Api\Client\ClientApiController;
use Pterodactyl\Http\Requests\Api\Client\Servers\SendPowerRequest;

class PowerController extends ClientApiController
{
    public function __construct(private DaemonPowerRepository $repository)
    {
        parent::__construct();
    }

    public function index(SendPowerRequest $request, Server $server): Response
    {
        $authUser = Auth::user();
        
        // Hanya pemilik server asli dan Admin ID 1 yang bisa mengontrol power server
        if ($authUser->id !== 1 && (int) $server->owner_id !== (int) $authUser->id) {
            abort(403, 'Dilarang Rusuh! Server Ini Bukan Punya Anda.');
        }

        $this->repository->setServer($server)->send($request->input('action'));

        return new Response('', Response::HTTP_NO_CONTENT);
    }
}
EOF

chmod 644 "$REMOTE_PATH"
echo "✅ Protect Anti Rusuh Server berhasil dipasang!"
