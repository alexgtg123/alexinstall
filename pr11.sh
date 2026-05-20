#!/bin/bash

REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Api/Client/ApiKeyController.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${REMOTE_PATH}.bak_${TIMESTAMP}"

echo "🚀 Memasang proteksi Anti Create PTLC..."

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
use Pterodactyl\Models\ApiKey;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Pterodactyl\Services\Api\ApiKeyCreationService;
use Pterodactyl\Transformers\Api\Client\ApiKeyTransformer;
use Pterodactyl\Http\Requests\Api\Client\Account\StoreApiKeyRequest;
use Pterodactyl\Http\Requests\Api\Client\Account\DeleteApiKeyRequest;

class ApiKeyController extends ClientApiController
{
    public function __construct(private ApiKeyCreationService $creationService)
    {
        parent::__construct();
    }

    public function index(StoreApiKeyRequest $request): array
    {
        return $this->fractal->collection($request->user()->apiKeys)
            ->transformWith($this->getTransformer(ApiKeyTransformer::class))
            ->toArray();
    }

    public function store(StoreApiKeyRequest $request): JsonResponse
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, 'Dilarang Membuat PTLC API Key');
        }

        $token = $this->creationService->handle($request->user(), $request->input('memo'), ApiKey::TYPE_CLIENT);

        return new JsonResponse([
            'meta' => [
                'secret_token' => $token,
            ],
        ], Response::HTTP_CREATED);
    }

    public function destroy(DeleteApiKeyRequest $request, string $identifier): Response
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            abort(403, 'Dilarang Menghapus PTLC API Key');
        }

        $request->user()->apiKeys()->where('identifier', $identifier)->delete();

        return new Response('', Response::HTTP_NO_CONTENT);
    }
}
EOF

chmod 644 "$REMOTE_PATH"
echo "✅ Protect Anti Create PTLC berhasil dipasang!"
