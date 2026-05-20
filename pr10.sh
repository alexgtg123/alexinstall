#!/bin/bash

REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Api/Client/TwoFactorController.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${REMOTE_PATH}.bak_${TIMESTAMP}"

echo "🚀 Memasang proteksi Anti Button Two Factor..."

if [ -f "$REMOTE_PATH" ]; then
  mv "$REMOTE_PATH" "$BACKUP_PATH"
  echo "📦 Backup file lama dibuat di $BACKUP_PATH"
fi

mkdir -p "$(dirname "$REMOTE_PATH")"
chmod 755 "$(dirname "$REMOTE_PATH")"

cat > "$REMOTE_PATH" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Api\Client;

use Illuminate\Http\Response;
use Pterodactyl\Http\Requests\Api\Client\TwoFactorRequest;
use Pterodactyl\Http\Controllers\Api\Client\ClientApiController;
use Illuminate\Support\Facades\Auth;

class TwoFactorController extends ClientApiController
{
    /**
     * Returns 2FA token generation details.
     */
    public function index(TwoFactorRequest $request): array
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, 'Fitur 2FA Dinonaktifkan oleh Admin Utama');
        }

        return [
            'data' => [
                'qr_by_key_url' => $request->user()->getTwoFactorDetails(),
            ],
        ];
    }

    /**
     * Updates 2FA state for a user.
     */
    public function update(TwoFactorRequest $request): Response
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, 'Fitur 2FA Dinonaktifkan oleh Admin Utama');
        }

        $request->user()->updateTwoFactor($request->input('code'));

        return new Response('', Response::HTTP_NO_CONTENT);
    }

    /**
     * Deletes 2FA state for a user.
     */
    public function destroy(TwoFactorRequest $request): Response
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, 'Fitur 2FA Dinonaktifkan oleh Admin Utama');
        }

        $request->user()->disableTwoFactor();

        return new Response('', Response::HTTP_NO_CONTENT);
    }
}
EOF

chmod 644 "$REMOTE_PATH"
echo "✅ Protect Anti Button 2FA berhasil dipasang!"
