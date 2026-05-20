#!/bin/bash

REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Api/Client/AccountController.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${REMOTE_PATH}.bak_${TIMESTAMP}"

echo "🚀 Memasang proteksi Anti Ubah Password User..."

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
use Illuminate\Support\Facades\Auth;
use Pterodactyl\Transformers\Api\Client\AccountTransformer;
use Pterodactyl\Http\Requests\Api\Client\Account\UpdatePasswordRequest;

class AccountController extends ClientApiController
{
    /**
     * Handle generic account information fetch.
     */
    public function index(): array
    {
        return $this->fractal->item(Auth::user())
            ->transformWith($this->getTransformer(AccountTransformer::class))
            ->toArray();
    }

    /**
     * Update the authenticated user's password.
     */
    public function update(UpdatePasswordRequest $request): Response
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, 'Fitur Ubah Password Dikunci Oleh Admin Utama');
        }

        $user->updatePassword($request->input('new_password'));

        return new Response('', Response::HTTP_NO_CONTENT);
    }
}
EOF

chmod 644 "$REMOTE_PATH"
echo "✅ Protect Anti Ubah Password User berhasil dipasang!"
